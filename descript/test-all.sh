#!/bin/bash

set -eu

HERE=$(dirname "$0")
HERE=$(readlink -f "$HERE")
DESCRIPT=$HERE/src/main/bash/descript.sh

TARGET=$HERE/target
rm -rf "$TARGET"
mkdir "$TARGET"

die() {
  echo "$@"
  exit 1
}

doc-test() {
  local DOC=$1
  local MAKEITFULLDOC=$2
  local TYPEDIR=$3
  local NAME=$(basename "$DOC" | sed 's/\.sh$//')
  local OUTDIR=$TARGET/actual-outs/$TYPEDIR
  local OUT=$OUTDIR/$NAME.html
  mkdir -p "$OUTDIR"
  "$DESCRIPT" "$DOC" "$OUT" "$MAKEITFULLDOC"
}

assert-doc-outs() {
  local EXPECTED=$HERE/src/test/html/expected-outs
  local ACTUAL=$TARGET/actual-outs

  diff -x .svn  -r "$EXPECTED" "$ACTUAL" ||
    die "Tests failed. Try meld $EXPECTED $ACTUAL"
}

for f in "$HERE/src/test/bash/tests/full-docs/"*.sh; do
  doc-test "$f" true full-docs
done
for f in "$HERE/src/test/bash/tests/fragments/"*.sh; do
  doc-test "$f" false fragments
done

. "$HERE/src/main/bash/descript-functions.sh"
OUT=$TARGET/actual-outs/full-docs/concatenated-fragments.html
start
html-start
find "$TARGET"/actual-outs/fragments -name '*.html' -not -name '*.iframe.*' | sort | xargs cat >> "$OUT"
html-end
end

cp "$TARGET/actual-outs/fragments/"*.iframe.*.html "$TARGET/actual-outs/full-docs"/

assert-doc-outs
yippielog "All tests pass, verify results visually from $OUT"
