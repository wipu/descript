doc() {
section "Console shows all whitespace and overlong lines"
cmd 'echo  "all  "   whitespace is preserved     .'
cmd 'echo "  And overlong lines are broken automatically, but there is no linebreak, so the reader can copy-paste the text without getting any   extra   linebreaks.  "'
cmd "mkdir 'extra   whitespace   also works in prompt  '"
cmd "cd 'extra   whitespace   also works in prompt  '"
cmd 'echo lines are not broken at word boundary. Thisoverlongwordcannotbeononelineonlyinsteaditmustbebrokenatsomepoint.'
cmd 'echo empty line; echo; echo in output'
cmd "cd .."
}
