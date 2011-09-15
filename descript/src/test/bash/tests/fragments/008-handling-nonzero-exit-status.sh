doc() {
section "Handling non-zero exit status of commands"

cmd 'die() { html "died: $@"; }'

p "A non-zero exit status is an error, if using the cmd function."
cmd "false"
p "Function failing-cmd must be used instead."
failing-cmd 1 "false"
p "It's an error if the failing-cmd exits with zero."
failing-cmd 1 "true"
p "The bash special parameter $? always expands to 0, to keep descript more robust. TODO maybe it would be better not to use set -eu."

cmd 'die() { echo "$@"; exit 1; }'

cmd "true"
cmd 'echo $?'
out-was <<EOF
0
EOF
failing-cmd 1 "false"
cmd 'echo $?'
out-was <<EOF
0
EOF
}
