doc() {
section "Asserting output of cmd"

cmd 'die() { html "died: $@"; }'

p "Function out-was can be used to assert cmd output"
p "First, the empty case, success:"
cmd "true"
echo -n | out-was
p "And failure:"
cmd "true"
out-was <<EOF
Something
EOF
p "Then non-empty:"
cmd 'echo "non-empty output"'
out-was <<EOF
non-empty output
EOF
cmd 'echo "actual"'
out-was <<EOF
expected
EOF

cmd 'die() { errorlog "$@"; exit 1; }' 

p "stdout and stderr get combined. TODO is there a way to interleave them naturally but still assert them separately?"
cmd 'echo err > /dev/stderr'
out-was <<EOF
err
EOF
cmd 'echo out >> /dev/stdout && echo err >> /dev/stderr'
out-was <<EOF
out
err
EOF
p "Since descript uses files to capture output, append is necessary:"
cmd 'echo out > /dev/stdout && echo err > /dev/stderr'
out-was <<EOF
err
EOF
}
