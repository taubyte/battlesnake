#!/bin/bash

export PATH="/usr/local/go/bin:/usr/local/tinygo/bin:${PATH}"

. /utils/wasm.sh

build "${FILENAME}"
ret=$?
echo -n $ret > /out/ret-code
exit $ret
