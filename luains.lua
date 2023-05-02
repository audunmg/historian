#!/usr/bin/env lua

local os = require("os")
local sqlite3 = require("lsqlite3")

local db = assert(sqlite3.open(assert(os.getenv('HISTDB'))))

-- Map environment sql table names to environment variables
vars = {
    bash_pid = "BASH_PID",
    columns = "COLUMNS",
    command = "READLINE_LINE",
    history_lineno = "HISTORY_LINE",
    lines = "LINES",
    pwd = "PWD",
    session_start = "SESSION_START",
    tty = "TTY",
    ssh_connection = "SSH_CONNECTION"
}

sqlnames = ""
mark     = ""
values = {}
for k,v in pairs(vars) do
  if (os.getenv(v)) then
    sqlnames = sqlnames .. ", " .. k
    mark     = mark .. ", ?"
    table.insert( values, os.getenv(v) )
  end
end


insert_stmt = db:prepare( "INSERT INTO bashhistory (time" .. sqlnames .. ") VALUES (julianday('now')" .. mark .. ")"  )

insert_stmt:bind_values( table.unpack( values ) )

insert_stmt:step()
insert_stmt:reset()
