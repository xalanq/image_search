package main

import (
	"bytes"
	"context"
	"encoding/csv"
	"encoding/json"
	"fmt"
	"image"
	"io/ioutil"
	"log"
	"os"
	"os/signal"
	"path"
	"runtime"
	"strconv"
	"strings"
	"sync"
	"sync/atomic"
	"syscall"
	"time"

	"github.com/h2non/bimg"
	"github.com/lucasb-eyer/go-colorful"
	"github.com/olivere/elastic/v7"
	"github.com/xalanq/prominentcolor"
)

const (
	dataSavedPath   = "../data/images.json"
	imagesPath      = "../data/train_0"
	labelsPath      = "../data/class-descriptions-boxable.csv"
	imageLabelsPath = "../data/train-annotations-human-imagelabels-boxable.csv"
	imageMetasPath  = "../data/oidv6-train-images-with-labels-with-rotation.csv"

	esURL     = "http://127.0.0.1:9200"
	esIndex   = "image"
	esMapping = `
	  {
		"settings": {
		  "number_of_shards": 1,
		  "number_of_replicas": 0,
		  "analysis": {
			"filter": {
			  "english_stop": {
				"type": "stop",
				"stopwords": "_english_"
			  },
			  "english_keywords": {
				"type": "keyword_marker",
				"keywords": [
				  "example"
				]
			  },
			  "english_stemmer": {
				"type": "stemmer",
				"language": "english"
			  },
			  "english_possessive_stemmer": {
				"type": "stemmer",
				"language": "possessive_english"
			  }
			},
			"analyzer": {
			  "rebuilt_english": {
				"tokenizer": "standard",
				"filter": [
				  "english_possessive_stemmer",
				  "lowercase",
				  "english_stop",
				  "english_keywords",
				  "english_stemmer"
				]
			  }
			}
		  }
		},
		"mappings": {
		  "properties": {
			"path": {
			  "type": "text",
			  "index": false
			},
			"url": {
			  "type": "text",
			  "index": false
			},
			"landing_url": {
			  "type": "text",
			  "index": false
			},
			"labels": {
			  "type": "text",
			  "analyzer": "rebuilt_english"
			},
			"title": {
			  "type": "text",
			  "analyzer": "rebuilt_english"
			},
			"size": {
			  "type": "long",
			  "index": false
			},
			"width": {
			  "type": "long"
			},
			"height": {
			  "type": "long"
			},
			"colors": {
			  "type": "nested",
			  "properties": {
				"h": {
				  "type": "double"
				},
				"s": {
				  "type": "double"
				},
				"l": {
				  "type": "double"
				},
				"ratio": {
				  "type": "double"
				}
			  }
			}
		  }
		}
	  }
`
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
	Labels     []string   `json:"labels" binding:"required"`
	Title      string     `json:"title" binding:"required"`
	Size       int        `json:"size" binding:"required"`
	Width      int        `json:"width" binding:"required"`
	Height     int        `json:"height" binding:"required"`
	Colors     []ColorHSL `json:"colors" binding:"required"`
}

var images map[string]*Image

func load() {
	b, err := ioutil.ReadFile(dataSavedPath)
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
	err = ioutil.WriteFile(dataSavedPath, b, 0644)
	if err != nil {
		panic(err)
	}
}

func read_image_list() {
	files, err := ioutil.ReadDir(imagesPath)
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
	files, err := ioutil.ReadDir(imagesPath)
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

		buffer, err := bimg.Read(path.Join(imagesPath, name))
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
	files, err := ioutil.ReadDir(imagesPath)
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
					defer func() {
						i := atomic.AddInt64(&counter, 1)
						if i%100 == 0 {
							fmt.Printf("%v/%v, %.2f%%, spent: %v, estimate: %v\n", i, total, float64(i)/float64(total)*100, time.Now().Sub(begin).String(), time.Duration(float64(time.Now().Sub(begin))/float64(i)*float64(total-i)).String())
						}
					}()
					name := f.Name()
					if name[len(name)-4:] != ".jpg" {
						panic("gg")
					}
					id := name[:len(name)-4]
					/*
						if len(images[id].Colors) != 0 {
							return
						}
					*/

					file, err := os.Open(path.Join(imagesPath, name))
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
						colorhsls = append(colorhsls, ColorHSL{
							H:     h,
							S:     s,
							L:     l,
							Ratio: float64(color.Cnt) / float64(numPixels),
						})
					}
					images[id].Colors = colorhsls
				}()
			}
		}()
	}
	// send data to ch
	for _, file := range files {
		ch <- file
	}
	close(ch)
	wg.Wait()
}

var labels map[string]string

func read_label() {
	data, err := ioutil.ReadFile(labelsPath)
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
	data, err := ioutil.ReadFile(imageLabelsPath)
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
	data, err := ioutil.ReadFile(imageMetasPath)
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

func import_data_to_es() {
	ctx := context.Background()
	client, err := elastic.NewSimpleClient(elastic.SetURL(esURL))
	if err != nil {
		panic(err)
	}
	_, _, err = client.Ping(esURL).Do(ctx)
	if err != nil {
		panic(err)
	}

	exists, err := client.IndexExists(esIndex).Do(ctx)
	if err != nil {
		panic(err)
	}
	if exists {
		client.DeleteIndex(esIndex).Do(ctx)
	}
	_, err = client.CreateIndex(esIndex).BodyString(esMapping).Do(ctx)
	if err != nil {
		panic(err)
	}

	total := int64(len(images))
	begin := time.Now()

	numberOfGoroutine := runtime.GOMAXPROCS(2)
	type Data struct {
		ID    string
		Image *Image
	}
	ch := make(chan Data, numberOfGoroutine)
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
					defer func() {
						i := atomic.AddInt64(&counter, 1)
						if i%100 == 0 {
							fmt.Printf("%v/%v, %.2f%%, spent: %v, estimate: %v\n", i, total, float64(i)/float64(total)*100, time.Now().Sub(begin).String(), time.Duration(float64(time.Now().Sub(begin))/float64(i)*float64(total-i)).String())
						}
					}()

					id := f.ID
					image := f.Image

					_, err := client.Index().Index(esIndex).Id(id).BodyJson(image).Do(ctx)
					if err != nil {
						panic(err)
					}
				}()
			}
		}()
	}

	// send data to ch
	for id, image := range images {
		ch <- Data{
			ID:    id,
			Image: image,
		}
	}
	close(ch)
	wg.Wait()
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
	import_data_to_es()
}
