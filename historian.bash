#!/bin/bash


# CREATE TABLE bashhistory( lines INTEGER, columns INTEGER, session_start INTEGER, bash_pid INTEGER, ssh_connection TEXT, tty TEXT, time REAL, command TEXT, pwd TEXT, return_value INTEGER, duration_msec INTEGER, id INTEGER PRIMARY KEY ASC, history_lineno INTEGER, hostname TEXT);
export HISTDB=$HOME/.bashhistory.db
shopt -s histappend

unset HISTFILE
unset HISTFILESIZE
unset HISTSIZE
unset HISTTIMEFORMAT

export TTY="$(readlink /dev/fd/0)"
export SESSION_START="$(lua -e 'p = require("posix") print(p.stat("/proc/'$$'").ctime)')"

function historysaver() {
    #historyhandler
    if [ -z "$READLINE_LINE"  ]; then
         return
    fi

    export LINES COLUMNS HOSTNAME
    # default
    line="${READLINE_POINT}"
    BASH_PID=$$ HISTORY_LINE=$HISTCMD "$HISTORIANDIR"/luains.lua
}

function _history() {
    #if [ -z "$1" ]; then
    #    builtin history
    #    return
    #fi
    BASH_PID=$$ "$HISTORIANDIR"/luaquery.lua "$@"
}

alias history=_history
bind -x '"\377": historysaver'
bind    'Control-m: "\xff\C-j"'
bind    '"\C-j"':accept-line

