package lib

// Battlesnake tournament snake — edit snake.go, then: bash scripts/test.sh && bash scripts/deploy.sh
//
// POST /move receives game state JSON, return {"move":"up|down|left|right"}

import (
	"encoding/json"
	"io"
	"math/rand"

	"github.com/taubyte/go-sdk/event"
	http "github.com/taubyte/go-sdk/http/event"
)

type coord struct {
	X int `json:"x"`
	Y int `json:"y"`
}

type snake struct {
	ID   string  `json:"id"`
	Body []coord `json:"body"`
	Head coord   `json:"head"`
}

type board struct {
	Height int     `json:"height"`
	Width  int     `json:"width"`
	Food   []coord `json:"food"`
}

type moveRequest struct {
	Board board `json:"board"`
	You   snake `json:"you"`
}

type moveResponse struct {
	Move string `json:"move"`
}

var directions = []string{"up", "down", "left", "right"}

var deltas = map[string]coord{
	"up":    {X: 0, Y: -1},
	"down":  {X: 0, Y: 1},
	"left":  {X: -1, Y: 0},
	"right": {X: 1, Y: 0},
}

func occupied(c coord, snakes []snake, selfID string, board board) bool {
	if c.X < 0 || c.Y < 0 || c.X >= board.Width || c.Y >= board.Height {
		return true
	}
	for _, s := range snakes {
		for _, part := range s.Body {
			if part.X == c.X && part.Y == c.Y {
				if s.ID == selfID && part.X == s.Head.X && part.Y == s.Head.Y {
					continue
				}
				return true
			}
		}
	}
	return false
}

func safeMoves(req moveRequest, snakes []snake) []string {
	head := req.You.Head
	var safe []string
	for _, dir := range directions {
		d := deltas[dir]
		next := coord{X: head.X + d.X, Y: head.Y + d.Y}
		if !occupied(next, snakes, req.You.ID, req.Board) {
			safe = append(safe, dir)
		}
	}
	return safe
}

func pickMove(req moveRequest, snakes []snake) string {
	safe := safeMoves(req, snakes)
	if len(safe) == 0 {
		return directions[rand.Intn(len(directions))]
	}

	head := req.You.Head
	for _, food := range req.Board.Food {
		for _, dir := range safe {
			d := deltas[dir]
			next := coord{X: head.X + d.X, Y: head.Y + d.Y}
			if next.X == food.X && next.Y == food.Y {
				return dir
			}
		}
	}

	return safe[rand.Intn(len(safe))]
}

func writeJSON(h http.Event, status int, payload any) uint32 {
	body, err := json.Marshal(payload)
	if err != nil {
		return 1
	}
	if err := h.Headers().Set("Content-Type", "application/json"); err != nil {
		return 1
	}
	if _, err := h.Write(body); err != nil {
		return 1
	}
	if err := h.Return(status); err != nil {
		return 1
	}
	return 0
}

//export Move
func Move(e event.Event) uint32 {
	h, err := e.HTTP()
	if err != nil {
		return 1
	}

	bodyReader := h.Body()
	defer bodyReader.Close()
	body, err := io.ReadAll(bodyReader)
	if err != nil {
		return writeJSON(h, 400, map[string]string{"error": "invalid body"})
	}

	var req moveRequest
	if err := json.Unmarshal(body, &req); err != nil {
		return writeJSON(h, 400, map[string]string{"error": "invalid json"})
	}

	// Battlesnake sends full game state; we only decode what we need.
	var raw map[string]json.RawMessage
	_ = json.Unmarshal(body, &raw)
	var snakes []snake
	if boardRaw, ok := raw["board"]; ok {
		var fullBoard struct {
			Snakes []snake `json:"snakes"`
		}
		_ = json.Unmarshal(boardRaw, &fullBoard)
		snakes = fullBoard.Snakes
	}

	move := pickMove(req, snakes)
	return writeJSON(h, 200, moveResponse{Move: move})
}
