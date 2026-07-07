# Tournament Checklist

Quick reference for participants. Full docs: [README.md](README.md).

## Steps

| # | Action | Command |
| --- | --- | --- |
| 1 | Fork repo + open Codespace (4-core / 8 GB) | GitHub UI |
| 2 | Start Dream (terminal 1, leave open) | `bash scripts/dream-foreground.sh` |
| 3 | Setup (terminal 2) | `bash scripts/init.sh` |
| 4 | Write your snake | Edit `snake.go` only |
| 5 | Local Dream build gate | `bash scripts/test.sh` |
| 6 | Deploy to aventr.cloud | `bash scripts/deploy.sh` |
| 7 | Register snake | Paste `https://<fqdn>/move` at [play.battlesnake.com](https://play.battlesnake.com) |

## Iterate loop

```bash
# edit snake.go
bash scripts/test.sh
bash scripts/deploy.sh
```

## Acceptance criteria

- [ ] Codespace opens with `tau`, `dream`, and Docker ready
- [ ] `bash scripts/init.sh` completes without errors
- [ ] `bash scripts/test.sh` passes (Dream build succeeds)
- [ ] `bash scripts/deploy.sh` prints a live `https://.../move` URL
- [ ] Battlesnake accepts the URL and your snake responds to moves

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| "Not logged in" | `bash scripts/tau-login.sh` |
| "Run init first" | `bash scripts/init.sh` |
| Dream build timeout | `dream status universe default`, retry `test.sh` |
| Deploy build failed | `bash scripts/logs.sh`, fix code, retry |
| No project | Re-run `bash scripts/init.sh` |

## Rules

- Edit **only** `snake.go` in the participant repo.
- Do not edit `project/` or `scripts/lib/templates/` — those are managed by scripts.
- All Taubyte operations go through `tau` CLI (wrapped by scripts).
