package lib

import (
	"github.com/taubyte/go-sdk/event"
)

//export Health
func Health(e event.Event) uint32 {
	h, err := e.HTTP()
	if err != nil {
		return 1
	}
	if err := h.Headers().Set("Content-Type", "text/plain; charset=utf-8"); err != nil {
		return 1
	}
	if _, err := h.Write([]byte("battlesnake ok")); err != nil {
		return 1
	}
	if err := h.Return(200); err != nil {
		return 1
	}
	return 0
}
