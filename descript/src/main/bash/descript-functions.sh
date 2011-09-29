# to be sourced

die() {
  errorlog "$@"
  exit 1
}

start() {
  DESCRIPT_TMP=$OUT.tmp
  debuglog "Creating $DESCRIPT_TMP"
  mkdir -p "$DESCRIPT_TMP"
  debuglog "Emptying $OUT"
  echo -n > "$OUT"
  ORIGINALPWD=$PWD
  WORKAREA=$DESCRIPT_TMP/workarea
  debuglog "cding into $WORKAREA"
  mkdir "$WORKAREA"
  cd "$WORKAREA"
}

end() {
  debuglog "cding back to $ORIGINALPWD"
  cd "$ORIGINALPWD"
  debuglog "Deleting $DESCRIPT_TMP"
  rm -rf "$DESCRIPT_TMP"
}

printlog() {
  echo "---- $@" >> /dev/stderr
}

log() {
  logcolor 1
  logcolor 34
  printlog "$@"
  logcolor 0
}

debuglog() {
  logcolor 36
  printlog "$@"
  logcolor 0
}

errorlog() {
  logcolor 1
  logcolor 31
  printlog "$@"
  logcolor 0
}

yippielog() {
  logcolor 32
  printlog "$@"
  logcolor 0
}

logcolor() {
  # TODO why doesn't [ -t 1 ] && printf... work here?
  if [ -t 2 ]; then printf "\033[${1}m"; fi
}

to-article() {
  cat >> "$OUT"
}

html() {
  echo -n "$@" | to-article
}

html-line() {
  echo "$@" | to-article
}

p() {
  html-line "<p class='text'>"
  echo "$@" | xml-quoted | to-article
  html-line "</p>"
}

html-start() {
to-article <<EOF
<html><head>
<style type='text/css'>
body {font: 12px verdana, arial, sans-serif;}
.text {width:65em;}
.console {background-color:black;font-family:monospace;margin-left:33px;width:60em;}
.prompt {font-weight:bold;color:green;}
.cmd {color:white;}
.output {color:gray;}
.output-asserted {font-size:8px; background-color: #def9de;; margin-left:33px;}
.editor {border-style:solid;border-width:1px;margin-left:30px;margin-top:5px;margin-bottom:5px;background-color: #ffffd0;;width:60em;padding:2px;}
div.line {white-space:pre;margin-bottom:1px;}
div.add  {background-color: #def9de;;}
div.del  {background-color: #f9dede;; text-decoration:line-through;}
div.keep {background-color: #ffffff;;}
</style>
</head><body>
EOF
}

html-end() {
to-article <<EOF
</body>
</html>
EOF
}

xml-quoted() {
  sed 's/\&/\&amp;/g' |
  sed 's/</\&lt;/g'
}

# TODO good name for this
encoded() {
  echo "$@" | xml-quoted
}

section() {
local CAPTION=$(encoded "$@")
to-article <<EOF
<h2>$CAPTION</h2>
EOF
}

_cmd() {
  log "   _cmd: $@"
  local EXPECTED_STATUS=$1
  shift
  cmd-line "$@"
  html "<div class='console output'>"
  local CMDTMP=$DESCRIPT_TMP/tmp.sh
  LASTOUT=$DESCRIPT_TMP/out
  echo "$@" > "$CMDTMP"
  set +e
  . "$CMDTMP" > "$LASTOUT" 2>&1
  local ACTUAL_STATUS=$?
  debuglog "exit status: $ACTUAL_STATUS"
  debuglog "out:"
  cat "$LASTOUT" >> /dev/stderr
  set -e
  [ "$ACTUAL_STATUS" == "$EXPECTED_STATUS" ] ||
    die "Command '$@' exited with status $ACTUAL_STATUS. It should have been $EXPECTED_STATUS."
  cat "$LASTOUT" | forged-path | xml-quoted | spaced | to-article
  html-line "</div>"
}

failing-cmd() {
  _cmd "$@"
}

cmd() {
  _cmd 0 "$@"
}

out-was() {
  debuglog "Asserting out $LASTOUT"
  local EXPECTED=$DESCRIPT_TMP/expected-out
  cat > "$EXPECTED"
  debuglog "$EXPECTED"
  diff "$LASTOUT" "$EXPECTED" || die "Error in command output, see diff output for details."
  echo "<div><span class='output-asserted'><i>Output asserted</i></span></div>" | to-article
}

to-relative() {
  local PREFIX=$1
  sed "s:$WORKAREA:$PREFIX:g"
}

prompt() {
  local PROMPT=$(pwd | to-relative '~')
  debuglog "prompt: $PROMPT"
  PROMPT=$(echo -n "$PROMPT" | spaced)
  html "<span class='prompt'>$PROMPT \$ </span>"
}

#  sed 's:\([^ ]\):<code>\1</code>:g' |


# nice span-like flow without extra linebreaks or other characters needed
# and no stripping of whitespace.
# whitespace=pre doesn't work because manual linebreaks needed
# emsp looks perfect but copy-pasted commands don't work (emsp is not space)
# well, browsers preserve consecutive spaces if there is a non-text element
# between them, so let's make it a 0-width image.
#
# the img hack is used for all characters for console-like breaking of
# lines (not word boundary but on any character)
#
# linebreaks get replaced with <br/> except on the last line
#
# hacked html entities (&amp; and &lt;) are dehacked.
# TODO find a less ugly way to handle them.
spaced() {
  sed 's:\(.\):\1<img width="0" />:g' |
  sed 's:\&<img width="0" />a<img width="0" />m<img width="0" />p<img width="0" />;<img width="0" />:\&amp;:g' |
  sed 's:\&<img width="0" />l<img width="0" />t<img width="0" />;<img width="0" />:\&lt;:g' |
  sed '$!s:$:<br/>:g'
}

cmd-line() {
  html "<div class='console'>"
  prompt
  local CMDLINE=$DESCRIPT_TMP/cmdline
  echo "$@" | forged-path > "$CMDLINE"
  html "<span class='cmd'>"
  cat "$CMDLINE" | xml-quoted | spaced | to-article
  html "</span>"
  html-line "</div>"
}

forged-path() {
  to-relative '/home/hacker'
}

editdir-of() {
  local FILE=$(readlink -f "$1")
  EDITDIR=$(echo "$FILE" | to-relative "$DESCRIPT_TMP/edits")
  debuglog "EDITDIR=$EDITDIR"
  [ -e "$EDITDIR" ] || {
    mkdir -p "$EDITDIR"
  }
  if [ -e "$FILE" ] ; then
    cp "$FILE" "$EDITDIR/current"
  else
    echo -n > "$EDITDIR/current"
  fi
}

unidiff2color() {
  sed "s/^+/<div class='add line'>/" |
  sed "s/^-/<div class='del line'>/" |
  sed "s/^ /<div class='keep line'>/" |
  sed 's:$:</div>:'
}

colordiff() {
  local ORIG=$1
  local NEW=$2
  local TOFILE=$3
  # overlong lines are not broken
  # the editor class style is supposed to contain whitespace:pre
  diff -d -U 100000 "$ORIG" "$NEW" | tail -n +4 | xml-quoted | unidiff2color > "$TOFILE"
}

edit() {
  local FILE=$1
  local EDITNAME=$2
  editdir-of "$FILE"
  cat > "$FILE"
  local NEW=$EDITDIR/$EDITNAME
  [ -e "$NEW" ] && die "You have already used name $EDITNAME for editing $FILE"
  cp "$FILE" "$NEW"
  local COLORDIFF=$EDITDIR/$EDITNAME.colordiff
  colordiff "$EDITDIR/current" "$FILE" "$COLORDIFF"
  cmd-line "\$EDITOR \"$FILE\""
  html-line "<div class='editor'>"
  cat "$COLORDIFF" | to-article
  html-line "</div>"
}

diffedit() {
  local FILE=$1
  local EDITNAME=$2
  local NEWFILE=$DESCRIPT_TMP/diffedit.file
  local DIFFFILE=$DESCRIPT_TMP/diffedit.diff
  cat > "$DIFFFILE"
  cp "$FILE" "$NEWFILE"
  patch -s "$NEWFILE" "$DIFFFILE"
  cat "$NEWFILE" | edit "$FILE" "$EDITNAME"
}
