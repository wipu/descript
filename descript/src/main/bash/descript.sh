#!/bin/bash

set -eu

HERE=$(dirname "$0")
HERE=$(readlink -f "$HERE")

. "$HERE/descript-functions.sh"

[ $# == 3 ] || die "Usage: $0 DOC OUT MAKEITFULLDOC"
DOC=$(readlink -f "$1")
OUT=$(readlink -f "$2")
MAKEITFULLDOC=$3

make-it-full-doc() {
  [ "true" == "$MAKEITFULLDOC" ]
}

log "Descripting $DOC"
. "$DOC"
start
make-it-full-doc && html-start
doc
make-it-full-doc && html-end
end
log "OK, document ready at $OUT"
