doc() {
section "Forged path"
p 'Absolute paths in output get forged, partly for security and partly for reproducible builds.'
cmd 'pwd'
out-was <<EOF
$PWD
EOF
p "But out-was assertions need to use real paths! Forging must be visual only."
cmd 'mkdir dir1 && cd dir1'
cmd 'pwd'
out-was <<EOF
$PWD
EOF
cmd 'echo $PWD/another-dir'
out-was <<EOF
$PWD/another-dir
EOF
p 'Absolute paths on command lines are also forged.'
cmd "echo PWD expanded in the descript script: $PWD"
out-was <<EOF
PWD expanded in the descript script: $PWD
EOF
p 'Home directory is forged, if absolute path points outside working area.'
cmd "readlink -f $HOME"
out-was <<EOF
$HOME
EOF
cmd "echo $HOME/some/path '$HOME/other/path'"
out-was <<EOF
$HOME/some/path $HOME/other/path
EOF

cmd 'cd ..'
}
