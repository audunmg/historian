#!/bin/bash


# CREATE TABLE bashhistory( lines INTEGER, columns INTEGER, session_start INTEGER, bash_pid INTEGER, ssh_connection TEXT, tty TEXT, time REAL, command TEXT, history_lineno INTEGER, pwd TEXT, return_value INTEGER, duration_msec INTEGER, id INTEGER PRIMARY KEY ASC);
export HISTDB=$HOME/.bashhistory.db
shopt -s histappend

unset HISTFILE
unset HISTFILESIZE
unset HISTSIZE
unset HISTTIMEFORMAT

export TTY="$(readlink /dev/fd/0)"
export SESSION_START="$(date +%s)"

function historysaver() {
    #historyhandler
    if [ -z "$READLINE_LINE"  ]; then
         return
    fi

    export LINES COLUMNS
    # default
    line="${READLINE_POINT}"
    BASH_PID=$$ HISTORY_LINE=$HISTCMD lua "$HISTORIANDIR"/luains.lua
}

function _history() {
    if [ -z "$1" ]; then
        builtin history
        return
    fi
    lua "$HISTORIANDIR"/luaquery.lua "$@"
}

bind -x '"\377": historysaver'
bind    'Control-m: "\xff\C-j"'
bind    '"\C-j"':accept-line

