# Taubyte Battlesnake Tournament

Fork this repo, write your snake in **`snake.go`**, validate locally with **Dream**, deploy to **aventr.cloud**, and register on **[play.battlesnake.com](https://play.battlesnake.com)**.

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/taubyte/battlesnake)

## The flow

```
Fork -> Codespaces -> init -> edit snake.go -> test -> deploy -> play
```

One terminal. You only ever edit **`snake.go`** — everything else is handled by the scripts via **`tau`** and **Dream**.

---

## 1. Fork & open Codespaces

1. Fork [taubyte/battlesnake](https://github.com/taubyte/battlesnake).
2. On your fork: **Code -> Codespaces -> Create codespace on main** (4-core / 8 GB).
3. Wait for the container to finish building (`tau` and `dream` are pre-installed from vendored binaries, same as [taubyte/workshops](https://github.com/taubyte/workshops)).
4. Taubyte agent skills from [taubyte/skills](https://github.com/taubyte/skills) are installed automatically.

## 2. Setup (once)

```bash
bash scripts/init.sh
```

Authenticates with `tau`, starts Dream, creates your Taubyte project (`tb_battlesnake` + `tb_code_battlesnake` repos), installs templates, and runs the initial Dream build.

## 3. Write your snake

Edit **`snake.go`**. Your handler receives Battlesnake game state on `POST /move` and returns:

```json
{ "move": "up" }
```

(`up` | `down` | `left` | `right`)

## 4. Test locally (Dream build gate)

```bash
bash scripts/test.sh
```

1. Compiles `snake.go` to WASM with Docker (`taubyte/go-wasi`)
2. Runs `dream inject push-all`
3. Waits for the Dream build and shows the result

Fix errors and re-run until it passes.

## 5. Deploy to aventr.cloud

```bash
bash scripts/deploy.sh
```

Selects `aventr.cloud`, imports your project, creates/updates the domain, pushes config + code, waits for the remote build, tests `POST /move`, and prints your live HTTPS URL.

## 6. Register

Copy the HTTPS URL from `deploy.sh` (`https://<your-fqdn>/move`) -> [play.battlesnake.com](https://play.battlesnake.com) -> create a snake -> paste the URL.

---

## Iterate

```bash
# edit snake.go
bash scripts/compile.sh   # optional fast compile check
bash scripts/test.sh      # Dream build gate
bash scripts/deploy.sh    # deploy + live test
```

## Scripts

| Command | What it does |
| --- | --- |
| `bash scripts/doctor.sh` | Preflight — checks tau, dream, docker, gh |
| `bash scripts/init.sh` | Once: Dream + tau project + templates + initial build |
| `bash scripts/compile.sh` | Docker WASM compile check (no cloud) |
| `bash scripts/test.sh` | Compile + `dream inject push-all` + wait for build |
| `bash scripts/deploy.sh` | Deploy to aventr.cloud + test `/move` |
| `bash scripts/logs.sh` | Recent build status on aventr.cloud |
| `bash scripts/tau-login.sh` | Log tau in (auto-runs on Codespace create) |

## Troubleshooting

| Problem | Fix |
| --- | --- |
| tau / auth errors | `bash scripts/tau-login.sh` |
| Dream not ready | `dream status universe default` then `bash scripts/init.sh` |
| Compile fails | Read Docker output, fix `snake.go`, run `compile.sh` again |
| Dream build fails | Check output from `test.sh`, fix `snake.go`, retry |
| Deploy fails | `bash scripts/logs.sh`, wait ~30s, retry `deploy.sh` |
| `/move` returns empty | Wait ~30s for deploy to settle, then retry `deploy.sh` |
| tau / dream not found | `bash post/init.sh` then **Codespaces: Rebuild Container** |
| Recovery mode / container error | Rebuild container; if still broken run `bash post/init.sh` |

---

MIT — see [LICENSE](LICENSE).
