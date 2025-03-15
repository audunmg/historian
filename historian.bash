#!/bin/bash


export HISTDB="${HISTDB:-$HOME/.bashhistory.db}"
shopt -u histappend

unset HISTFILE
unset HISTFILESIZE
unset HISTSIZE
unset HISTTIMEFORMAT

#export TTY="$(readlink /dev/fd/0)"
#export SESSION_START="$(lua -e 'p = require("posix") print(p.stat("/proc/'$$'").ctime)')"

function _history_start_session() {
    export TTY="${TTY:-$(readlink /dev/fd/0)}"
    export SESSION_START="$(lua -e 'p = require("posix") print(p.stat("/proc/'$$'").ctime)')"
    export BASH_PID=$$ 
    "$HISTORIANDIR"/luains.lua session
}

function historysaver() {
    #historyhandler
    if [ -z "$READLINE_LINE"  ]; then
        return
    fi

    export LINES COLUMNS HOSTNAME
    # default
    line="${READLINE_POINT}"
    BASH_PID=$$ HISTORY_LINE=$HISTCMD "$HISTORIANDIR"/luains.lua insert
}

function _historian_update() {
    BASH_PID=$$ ERRCODE="$1" DURATIONMILLISECONDS="$2" HISTORY_LINE="$3" "$HISTORIANDIR"/luains.lua update
}


function _history() {
    #if [ -z "$1" ]; then
    #    builtin history
    #    return
    #fi
    BASH_PID=$$ "$HISTORIANDIR"/luaquery.lua "$@"
}

_history_start_session

alias history=_history
bind -x '"\377": historysaver'
bind    'Control-m: "\xff\C-j"'
bind    '"\C-j"':accept-line

