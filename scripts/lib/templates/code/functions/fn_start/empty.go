package lib

import (
	"github.com/taubyte/go-sdk/event"
)

//export Start
func Start(e event.Event) uint32 {
	h, err := e.HTTP()
	if err != nil {
		return 1
	}
	if err := h.Headers().Set("Content-Type", "application/json"); err != nil {
		return 1
	}
	if _, err := h.Write([]byte("{}")); err != nil {
		return 1
	}
	if err := h.Return(200); err != nil {
		return 1
	}
	return 0
}
