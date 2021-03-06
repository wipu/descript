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
  if [ -t 2 ]; then printf "\033[${1}m" > /dev/stderr; fi
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
.console {background-color:black;color:red;font-family:monospace;margin-left:33px;width:60em;}
.shell {word-break:break-all;white-space:pre-wrap;display:inline;}
.prompt {font-weight:bold;color:green;}
.cmd {color:white;}
.output {color:gray;}
.output-asserted {font-size:8px; background-color: #def9de;; margin-left:33px;}
.editor {border-style:solid;border-width:1px;margin-left:30px;margin-top:5px;margin-bottom:5px;background-color: #ffffd0;;width:60em;padding:2px;}
div.line {white-space:pre;margin-bottom:1px;min-height:1em;}
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

cmde() {
  log "   cmde: $@"
  [ $# -lt 2 ] && die "Usage: PIPESTATUS CMDWORD..."
  local EXPECTED_STATUS=$1
  shift
  console-start
  cmd-line "$@"
  local CMDTMP=$DESCRIPT_TMP/tmp.sh
  LASTOUT=$DESCRIPT_TMP/out
  echo "$@" > "$CMDTMP"
  echo 'ACTUAL_STATUS=${PIPESTATUS[*]}' >> "$CMDTMP"
  set +e
  . "$CMDTMP" > "$LASTOUT" 2>&1
  debuglog "Actual pipe status: $ACTUAL_STATUS"
  debuglog "out:"
  cat "$LASTOUT" >> /dev/stderr
  set -e
  [ "$ACTUAL_STATUS" == "$EXPECTED_STATUS" ] ||
    die "Pipeline '$@' exited with status $ACTUAL_STATUS. It should have been $EXPECTED_STATUS."
  cat "$LASTOUT" | to-shell-lines "output"
  console-end
}

console-start() {
  html "<div class='console'><samp>"
}

console-end() {
  html-line "</samp></div>"
}


cmd() {
  cmde 0 "$@"
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
  echo "$PROMPT \$ " | to-shell-lines "prompt" false
}

to-shell-lines() {
    local CLASS=$1
    local BR=${2:-true}
    while IFS='' read -r LINE; do
	html "<kbd class='shell $CLASS'>"
	echo -n "$LINE" | forged-path | xml-quoted | to-article
	html "</kbd>"
	[ "$BR" == "true" ] && html-line "<br/>" || true
    done
}

cmd-line() {
  prompt
  local CMDLINE=$DESCRIPT_TMP/cmdline
  echo "$@" > "$CMDLINE"
  cat "$CMDLINE" | to-shell-lines "cmd"
}

forged-path() {
  to-relative '/home/hacker' | sed "s:$HOME:/home/hacker:g"
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
  sed "s:^+:<div class='add line'>:" |
  sed "s:^-:<div class='del line'>:" |
  sed "s:^ :<div class='keep line'>:" |
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
  console-start
  cmd-line "\$EDITOR \"$FILE\""
  console-end
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

browser() {
  [ $# == 2 ] || {
    die "Usage: browser FILE IFRAMENAME"
    return # needed when die disabled
  }
  local FILE=$1
  local IFRAMENAME=$2
  local IFRAMEFILE=$OUT.iframe.$IFRAMENAME.html
  log "browser $FILE"
  debuglog "IFRAMEFILE=$IFRAMEFILE"
  local IFRAMEFILEBASE=$(basename "$IFRAMEFILE")
  console-start
  cmd-line "\$BROWSER \"$FILE\""
  console-end
  [ -e "$FILE" ] || {
    die "Cannot browse, file does not exist: $FILE"
    return
  }
  [ -e "$IFRAMEFILE" ] && {
    die "Cannot browse, iframe name already used: $IFRAMENAME"
    return
  }
  cp "$FILE" "$IFRAMEFILE"
  html '<iframe src="'$IFRAMEFILEBASE'">Your browser does not support iframes.</iframe>'
}
