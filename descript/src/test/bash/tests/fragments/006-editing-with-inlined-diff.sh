doc() {
section "Editing file, inlined diff"
edit file1 creation <<EOF
line 1
line 2
EOF
diffedit file1 diffedit <<EOF
2a3
> line 3
EOF
cmd 'cat file1'
out-was <<EOF
line 1
line 2
line 3
EOF
}
