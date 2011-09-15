doc() {
section "Editing file, inlined content"
edit file1 creation <<EOF
file1 line1
file1 line2
EOF
cmd "cat file1"
out-was <<EOF
file1 line1
file1 line2
EOF

edit file1 mod-add <<EOF
file1 line1, modified
file1 line2
file1 line3, added
EOF
cmd "cat file1"
out-was <<EOF
file1 line1, modified
file1 line2
file1 line3, added
EOF
edit file1 del <<EOF
file1 line1, modified
file1 line3, added
EOF
cmd "cat file1"
out-was <<EOF
file1 line1, modified
file1 line3, added
EOF
}
