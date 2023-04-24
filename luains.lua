#!/usr/bin/env lua

local os = require("os")
local sqlite3 = require("lsqlite3")

local db = assert(sqlite3.open(assert(os.getenv('HISTDB'))))

if os.getenv('SSH_CONNECTION') then
insert_stmt = assert(db:prepare([[
INSERT INTO bashhistory 
(time, command, pwd, tty, lines, columns, ssh_connection)
VALUES
(julianday('now'), ?, ?, ?, ?, ?, ?)
]]))

insert_stmt:bind_values(
assert(os.getenv('READLINE_LINE')),
assert(os.getenv('PWD')),
assert(os.getenv('TTY')),
assert(os.getenv('LINES')),
assert(os.getenv('COLUMNS')),
assert(os.getenv('SSH_CONNECTION'))
)

else
insert_stmt = assert(db:prepare([[
INSERT INTO bashhistory 
(time, command, pwd, tty, lines, columns)
VALUES
(julianday('now'), ?, ?, ?, ?, ?)
]]))

insert_stmt:bind_values(
assert(os.getenv('READLINE_LINE')),
assert(os.getenv('PWD')),
assert(os.getenv('TTY')),
assert(os.getenv('LINES')),
assert(os.getenv('COLUMNS'))
)
end
insert_stmt:step()
insert_stmt:reset()
