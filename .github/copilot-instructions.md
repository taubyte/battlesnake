# Copilot instructions — Taubyte Battlesnake Tournament

## What the participant edits

- **Only** edit `snake.go` at the repo root.
- Package must be `package lib`.
- Export symbol must be `//export Move` (matches function config `call: Move`).

## What NOT to edit

- `project/` (generated Taubyte config + code repos)
- `scripts/lib/templates/` (maintainer-owned scaffolds)
- `.devcontainer/` (Codespace environment)

## Battlesnake contract

- Endpoint: `POST /move`
- Request: Battlesnake game state JSON
- Response: `{"move":"up"|"down"|"left"|"right"}`

## Workflow commands

```bash
bash scripts/init.sh    # once
bash scripts/test.sh    # Dream local build gate
bash scripts/deploy.sh  # deploy to aventr.cloud
```

## Taubyte SDK rules

- Use `github.com/taubyte/go-sdk` HTTP event API.
- `h.Headers().Set(...)` then `h.Write(...)` then `h.Return(status)` last.
- Use `h.Query().Get(key)` — not `h.URL().Query()`.

## When helping debug

- Compile errors: suggest `bash scripts/compile.sh`
- Dream build failures: suggest `bash scripts/test.sh` and read its output
- Deploy issues: suggest `bash scripts/logs.sh`
