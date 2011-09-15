doc() {
section "Redirects can be used"
cmd 'echo "it works" > file'
cmd 'cat file'
out-was <<EOF
it works
EOF
}
