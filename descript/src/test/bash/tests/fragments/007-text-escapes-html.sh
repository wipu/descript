doc() {
section "Text may contain reserved HTML characters: <i>i</i> and &"
p "This is a paragraph. It can contain <i>i</i> and &".
cmd 'echo "And also commands and their output: <i>i</i> and &"'
}
