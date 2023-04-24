#!/bin/bash


export HISTDB=$HOME/.bashhistory-2023.db
shopt -s histappend

unset HISTFILE
unset HISTFILESIZE
unset HISTSIZE
unset HISTTIMEFORMAT

export TTY="$(readlink /dev/fd/0)"

function historysaver() {
    #historyhandler
    if [ -z "$READLINE_LINE"  ]; then
         return
    fi
    # CREATE TABLE bashhistory(lines INTEGER, columns INTEGER, ssh_connection TEXT, tty TEXT, time REAL, command TEXT, pwd TEXT, id INTEGER PRIMARY KEY ASC);

    export LINES COLUMNS
    # default
    line="${READLINE_LINE@Q}"
    lua "$HISTORIANDIR"/luains.lua
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

