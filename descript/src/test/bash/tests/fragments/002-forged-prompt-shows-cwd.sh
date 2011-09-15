doc() {
section "Forged prompt shows current working directory"
cmd "mkdir dir1"
cmd "cd dir1"
cmd "mkdir dir2"
cmd "cd dir2"
cmd "cd .."
cmd "cd .."
cmd "# back"
}
