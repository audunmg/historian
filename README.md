# Bash history replacement

Still early stages.

Requires lua (5.4 i think?) and lsqlite3 for lua.

lsqlite3 can be installed from luarocks or aur/lua-lsqlite3 on arch.


To install, clone repo and add to .bashrc:

```
export HISTORIANDIR=replace this with path to cloned repo
export HISTDB=$HOME/.bashhistory.db
```

The database is not initialized automatically. To initialize the database, run: 

```
$HISTORIANDIR/luains.lua setup
```

## How it works

It captures the history using readline macros and inserting it into a sqlite3 database, using lua because it was just way faster than bash scripting. This is because with lua I can do inserts with prepared statements, and escaping will not be a problem. With bash, I can't use prepared statements, and need to carefully escape stuff and I had no patience for that.

Since I already used lua for inserts, I just reused it for querying the database.

It first was implemented using the bash DEBUG trap, but that actually doesn't store the whole line being ran, and sometimes was run several times, for example `ls| cat` would run the trap twice, once for `ls`, once for `cat`, but the `.bash_history` would contain `ls| cat`. Not ideal. Hooking into readline will actually capture history correctly.

### Readline trickery?

Bash allows you to remap readline key inputs to whatever you want, including running scripts.

So I remap the enter key.

But, the remapping can only do one of these things:
* run script
* readline command (accept-line means run the command)
* macro (insert characters or keypresses)

The solution is to remap enter, (or "Control-m", as readline thinks it is) to a macro, pressing two keys, the \377 key not usually found on a keyboard, and control-j which usually do the same as enter, accept-line.

Now, on each press of enter, the insert script is ran, inserting the current line into the database, and then the line is run as normal.
