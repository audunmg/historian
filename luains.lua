#!/usr/bin/env lua

os = require("os")
sqlite3 = require("lsqlite3")
posix = require("posix")
math = require("math")

db = assert(sqlite3.open(assert(os.getenv('HISTDB'))))
assert(os.getenv("BASH_PID"),"No bash pid environment variable")


-- FIXME, make a better session id
sessionid = assert(posix.stat("/proc/" .. os.getenv("BASH_PID")).ctime + ( os.getenv("BASH_PID") * math.floor(10 ^10)), "Couldn't create session id")

-- Map database names to environment variable names
if (arg[1] == "update") then
    assert(os.getenv("HISTORY_LINE"), "Error: No HISTORY_LINE")
    vars = {
        return_value = "ERRCODE",
        duration_msec = "DURATIONMILLISECONDS",
    }
elseif (arg[1] == "session") then
    vars = {
        -- historian_session = "HISTORIAN_SESSION",
        session_start = "SESSION_START",
        bash_pid = "BASH_PID",
        ssh_connection = "SSH_CONNECTION",
        tty = "TTY",
        hostname = "HOSTNAME",
        user = "USER"
    }
elseif (arg[1] == "insert") then
    vars = {
        -- historian_session = "HISTORIAN_SESSION",
        columns = "COLUMNS",
        command = "READLINE_LINE",
        history_lineno = "HISTORY_LINE",
        lines = "LINES",
        pwd = "PWD",
    }
elseif (arg[1] == "setup") then
    db:exec([[
        CREATE TABLE bashhistory (
            lines INTEGER,
            columns INTEGER,
            session_id INTEGER,
            time REAL,
            command TEXT,
            pwd TEXT,
            return_value INTEGER,
            duration_msec INTEGER,
            id INTEGER PRIMARY KEY ASC,
            history_lineno INTEGER);
        CREATE TABLE bashsession (
            session_id INTEGER PRIMARY KEY ,
            session_start INTEGER,
            bash_pid INTEGER,
            ssh_connection TEXT,
            tty TEXT,
            user TEXT,
            hostname TEXT);
        ]])
    assert(db:errcode(), db:errmsg())
    return
else
    print("This is not meant to be run manually")
    return
end
-- insert session id
sqlnames = {'session_id'}
valuenames     = {':SESSION_ID'}
values = {}
values['SESSION_ID'] = sessionid

for k,v in pairs(vars) do
  if (os.getenv(v)) then
    table.insert(sqlnames,  k)
    table.insert(valuenames, ":"..v)
    values[v] = os.getenv(v)
  end
end

stmt = ""
if (arg[1] == "update") then
    stmt = [[UPDATE bashhistory 
                SET (return_value,duration_msec) = (:ERRCODE,:DURATIONMILLISECONDS) 
                WHERE (session_id == :SESSION_ID and history_lineno == ]] .. os.getenv("HISTORY_LINE") .. ")" 
elseif (arg[1] == "session") then
    stmt = "INSERT INTO bashsession (" .. table.concat(sqlnames,",") .. ") VALUES (" .. table.concat(valuenames,",") .. ")"
elseif (arg[1] == "insert") then
    stmt = [[INSERT INTO bashhistory
               (time, ]] .. table.concat(sqlnames,",") .. [[)
               VALUES (julianday('now'), ]] .. table.concat(valuenames,",") .. ")"
end
insert_stmt = db:prepare(stmt )
assert(insert_stmt, "\nFailed to prepare statement: "..stmt .. "\nError: ".. db:errmsg() )
insert_stmt:bind_names( values )

insert_stmt:step()
insert_stmt:reset()
