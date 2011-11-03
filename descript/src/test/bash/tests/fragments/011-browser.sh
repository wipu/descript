
# todo provide in descript-functions:
die-disabled() {
  cmd 'die() { html "died: $@"; }'
}

die-enabled() {
  cmd 'die() { echo "$@"; exit 1; }'
}

doc() {
section "Mocked html browser"

p "First missing html file."

die-disabled
browser missing.html missing

p "Then missing name for the iframe file of a minimal html document."

edit a.html creation <<EOF
<html><body>
<p>Hello</p>
</body></html>
EOF

browser a.html

p "Minimal happy case."

die-enabled

browser a.html hello

p "Reusing iframe name fails."
die-disabled
edit a.html hello2 <<EOF
<html><body>
<p>Hello 2</p>
</body></html>
EOF
browser a.html hello
die-enabled

p "New browse succeeds with different iframe name."
browser a.html hello2

}
