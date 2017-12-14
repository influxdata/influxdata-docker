package dockerlib

import (
	"container/list"
	"fmt"
	"io"
	"strings"
)

type keyValuePair struct {
	key    string
	values []string
}

type Header struct {
	values *list.List
	index  map[string]*list.Element
}

func (h *Header) Add(key, value string) {
	e, ok := h.index[key]
	if !ok {
		h.Set(key, value)
		return
	}

	kv := e.Value.(*keyValuePair)
	kv.values = append(kv.values, value)
}

func (h *Header) Set(key, value string) {
	if h.index == nil {
		h.index = make(map[string]*list.Element)
	}
	if h.values == nil {
		h.values = list.New()
	}
	values := make([]string, 1)
	values[0] = value
	h.index[key] = h.values.PushBack(&keyValuePair{
		key:    key,
		values: values,
	})
}

func (h *Header) Write(w io.Writer) error {
	for front := h.values.Front(); front != nil; front = front.Next() {
		kv := front.Value.(*keyValuePair)
		if _, err := fmt.Fprintf(w, "%s: %s\n", kv.key, strings.Join(kv.values, ", ")); err != nil {
			return err
		}
	}
	return nil
}
