package main

import (
	"bytes"
	"encoding/csv"
	"encoding/json"
	"fmt"
	"image"
	"io/ioutil"
	"log"
	"os"
	"os/signal"
	"runtime"
	"strconv"
	"strings"
	"sync"
	"sync/atomic"
	"syscall"
	"time"

	"github.com/h2non/bimg"
	"github.com/lucasb-eyer/go-colorful"
	"github.com/xalanq/prominentcolor"
)

type ColorHSL struct {
	H     float64 `json:"h" binding:"required"`
	S     float64 `json:"s" binding:"required"`
	L     float64 `json:"l" binding:"required"`
	Ratio float64 `json:"ratio" binding:"required"`
}

type Image struct {
	Path       string     `json:"path" binding:"required"`
	URL        string     `json:"url" binding:"required"`
	LandingURL string     `json:"landing_url" binding:"required"`
	Labels     []string   `json:"labels"`
	Title      string     `json:"title"`
	Size       int        `json:"size" binding:"required"`
	Width      int        `json:"width" binding:"required"`
	Height     int        `json:"height" binding:"required"`
	Colors     []ColorHSL `json:"colors"`
}

var images map[string]*Image

func load() {
	b, err := ioutil.ReadFile("images.json")
	if err != nil {
		images = make(map[string]*Image)
		return
	}
	if err := json.Unmarshal(b, &images); err != nil {
		panic(err)
	}
}

func save() {
	b, err := json.Marshal(images)
	if err != nil {
		panic(err)
	}
	err = ioutil.WriteFile("images.json", b, 0644)
	if err != nil {
		panic(err)
	}
}

func read_image_list() {
	files, err := ioutil.ReadDir("../data/train_0")
	if err != nil {
		log.Fatal(err)
	}
	for _, f := range files {
		name := f.Name()
		if name[len(name)-4:] != ".jpg" {
			panic("gg")
		}
		id := name[:len(name)-4]
		image := &Image{
			Path: name,
		}
		images[id] = image
	}
}

func read_image_size() {
	files, err := ioutil.ReadDir("../data/train_0")
	if err != nil {
		log.Fatal(err)
	}
	total := len(files)
	for i, f := range files {
		name := f.Name()
		if name[len(name)-4:] != ".jpg" {
			panic("gg")
		}
		if i%10000 == 0 {
			fmt.Printf("%v/%v\n", i, total)
		}
		id := name[:len(name)-4]

		buffer, err := bimg.Read("../data/train_0/" + name)
		if err != nil {
			panic(err)
		}
		image := bimg.NewImage(buffer)
		meta, err := image.Metadata()
		if err != nil {
			panic(err)
		}

		images[id].Width = meta.Size.Width
		images[id].Height = meta.Size.Height
	}
}

func read_image_color() {
	files, err := ioutil.ReadDir("../data/train_0")
	if err != nil {
		log.Fatal(err)
	}
	total := int64(len(files))
	begin := time.Now()

	numberOfGoroutine := runtime.GOMAXPROCS(runtime.NumCPU())
	ch := make(chan os.FileInfo, numberOfGoroutine)
	wg := sync.WaitGroup{}
	wg.Add(numberOfGoroutine)
	counter := int64(0)

	for gid := 0; gid < numberOfGoroutine; gid++ {
		go func() {
			for {
				f, ok := <-ch
				if !ok {
					wg.Done()
					return
				}
				func() {

					name := f.Name()
					if name[len(name)-4:] != ".jpg" {
						panic("gg")
					}
					id := name[:len(name)-4]
					file, err := os.Open("../data/train_0/" + name)
					defer file.Close()
					if err != nil {
						panic(err)
					}
					img, _, err := image.Decode(file)
					if err != nil {
						panic(err)
					}
					colors, numPixels, err := prominentcolor.KmeansWithAll(3, img, prominentcolor.ArgumentDefault, 100, nil)
					if err != nil {
						fmt.Printf("%v error\n", name)
						panic(err)
					}
					colorhsls := []ColorHSL{}
					for _, color := range colors {
						h, s, l := colorful.Color{R: float64(color.Color.R) / 255.0, G: float64(color.Color.G) / 255.0, B: float64(color.Color.B) / 255.0}.Hsl()
						colorhsls = append(images[id].Colors, ColorHSL{
							H:     h,
							S:     s,
							L:     l,
							Ratio: float64(color.Cnt) / float64(numPixels),
						})
					}
					images[id].Colors = colorhsls
					i := atomic.AddInt64(&counter, 1)
					if i%100 == 0 {
						fmt.Printf("%v/%v, %.2f%%, cost: %v, estimate: %v\n", i+1, total, float64(i+1)/float64(total)*100, time.Now().Sub(begin).String(), time.Duration(float64(time.Now().Sub(begin))/float64(i+1)*float64(total-i-1)).String())
					}
				}()
			}
		}()
	}
	// send data to ch
	for _, file := range files {
		ch <- file
	}
	wg.Wait()
}

var labels map[string]string

func read_label() {
	data, err := ioutil.ReadFile("../data/class-descriptions-boxable.csv")
	if err != nil {
		panic(err)
	}
	rows, err := csv.NewReader(bytes.NewReader(data)).ReadAll()
	if err != nil {
		panic(err)
	}
	labels = make(map[string]string)
	for _, row := range rows {
		id := strings.TrimSpace(row[0])
		label := strings.TrimSpace(row[1])
		labels[id] = label
	}
}

func read_image_label() {
	data, err := ioutil.ReadFile("../data/train-annotations-human-imagelabels-boxable.csv")
	if err != nil {
		panic(err)
	}
	rows, err := csv.NewReader(bytes.NewReader(data)).ReadAll()
	if err != nil {
		panic(err)
	}
	for _, image := range images {
		image.Labels = nil
	}
	for _, row := range rows {
		imageID := strings.TrimSpace(row[0])
		labelID := strings.TrimSpace(row[2])
		confidence := strings.TrimSpace(row[3])
		if image, ok := images[imageID]; ok && confidence == "1" {
			image.Labels = append(image.Labels, labels[labelID])
		}
	}
}

func read_image_meta() {
	data, err := ioutil.ReadFile("../data/oidv6-train-images-with-labels-with-rotation.csv")
	if err != nil {
		panic(err)
	}
	rows, err := csv.NewReader(bytes.NewReader(data)).ReadAll()
	if err != nil {
		panic(err)
	}
	rows = rows[1:]
	for _, row := range rows {
		imageID := strings.TrimSpace(row[0])
		url := strings.TrimSpace(row[2])
		landingURL := strings.TrimSpace(row[3])
		title := strings.TrimSpace(row[7])
		size := strings.TrimSpace(row[8])
		if image, ok := images[imageID]; ok {
			image.URL = url
			image.LandingURL = landingURL
			image.Size, _ = strconv.Atoi(size)
			image.Title = title
		}
	}
}

func setClose() {
	c := make(chan os.Signal)
	signal.Notify(c, os.Interrupt, syscall.SIGTERM)
	go func() {
		<-c
		save()
		os.Exit(0)
	}()
}

func main() {
	defer func() {
		save()
	}()
	load()
	read_image_list()
	read_label()
	read_image_label()
	read_image_meta()
	read_image_size()
	read_image_color()
}
