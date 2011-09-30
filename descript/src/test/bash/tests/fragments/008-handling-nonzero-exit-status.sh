doc() {
section "Handling non-zero exit status of commands"

cmd 'die() { html "died: $@"; }'

p "A non-zero exit status is an error, if using the cmd function."
cmd "false"
p "Function cmde must be used instead."
cmde 1 "false"
p "It's an error if the cmde exits with different exit status."
cmde 1 "true"
p "Command statuses in a pipeline are asserted individually. First the happy case."
cmde "1 0" 'false | true'
cmde "0 1" 'true | false'
p "Then failure."
cmde "1 0" 'true | false'
p "The bash special parameter $? always expands to 0, to keep descript more robust. TODO maybe it would be better not to use set -eu."

cmd 'die() { echo "$@"; exit 1; }'

cmd "true"
cmd 'echo $?'
out-was <<EOF
0
EOF
cmde 1 "false"
cmd 'echo $?'
out-was <<EOF
0
EOF
}
