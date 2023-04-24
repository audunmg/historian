# Bash history replacement

Quite early stages.

Requires lua (5.4 i think?) and lsqlite3 for lua.

To install, clone repo and add to .bashrc:

```
export HISTORIANDIR=replace this with path to cloned repo
export HISTDB=$HOME/.bashhistory.db

```

The database is not initialized automatically. To initialize the database, run: 

```
sqlite "$HISTDB" 'CREATE TABLE bashhistory(lines INTEGER, columns INTEGER, ssh_connection TEXT, tty TEXT, time REAL, command TEXT, pwd TEXT, id INTEGER PRIMARY KEY ASC)'
```


## How it works

It captures the history using readline trickery and inserting it into a sqlite3 database, using lua because it was just way faster than bash scripting. Since I already used lua for inserts, I just reused it for querying the database.

It first was implemented using the bash DEBUG trap, but that actually doesn't store the whole line being ran, and sometimes was run several times, for example `ls| cat` would run the trap twice, once for `ls`, once for `cat`, but the `.bash_history` would contain `ls| cat`. Not ideal. Readline trickery actually captures history correctly.

### Readline trickery?

Bash allows you to remap readline key inputs to whatever you want, including running scripts.

So I remap the enter key.

But, the remapping can only do one of these things:
* run script
* readline command (accept-line means run the command)
* macro (insert characters or keypresses)

The solution is to remap enter, or "Control-m" to a macro, pressing two keys, the \377 key not usually found on a keyboard, and control-j which usually do the same as enter, accept-line.

Now, on each press of enter, the insert script is ran, inserting the current line into the database, and then the line is run as normal.
