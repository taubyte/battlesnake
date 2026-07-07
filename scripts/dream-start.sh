#!/usr/bin/env bash
# Alias — see dream-foreground.sh (run Dream in a second terminal).
exec "$(cd "$(dirname "$0")" && pwd)/dream-foreground.sh" "$@"
