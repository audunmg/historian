#!/usr/bin/env lua

local sqlite3 = require("lsqlite3")
local os = require("os")
local json = require("dkjson")

function createdb(db)
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
            session_start REAL,
            bash_pid INTEGER,
            ssh_connection TEXT,
            tty TEXT,
            user TEXT,
            hostname TEXT);
        ]])
        assert(db:errcode(), db:errmsg())
end


local db = assert(sqlite3.open(assert(arg[1],"Error no database to open"),sqlite3.OPEN_READONLY ))

local outdb = assert(sqlite3.open(arg[2]) )
-- assert(db:exec([[SELECT * FROM bashhistory;]]))
outdb:exec([[BEGIN TRANSACTION;]])
createdb(outdb)
s_stmt = [[ INSERT INTO bashsession 
              ( session_id, session_start, bash_pid, ssh_connection, tty, user, hostname) VALUES 
              (:session_id,:session_start,:bash_pid,:ssh_connection,:tty,:user,:hostname) ]]
session_ins = outdb:prepare(s_stmt)
assert(session_ins, "\nFailed statement:"..s_stmt.."\nError: "..outdb:errmsg())

r_stmt = [[INSERT INTO bashhistory (session_id,lines,columns,time,command,pwd,return_value,duration_msec,history_lineno ) VALUES ( :session_id,:lines,:columns,:time,:command,:pwd,:return_value,:duration_msec,:history_lineno)]]
r_ins = outdb:prepare(r_stmt)
assert(r_ins, "\nFailed statement:"..r_stmt.."\nError: "..outdb:errmsg())

sessions = {}
lines    = {}
for row in db:nrows([[SELECT 
    lines,columns,session_start,bash_pid,ssh_connection,tty,time,command,pwd,
    return_value,duration_msec,id,history_lineno,hostname,user
    FROM bashhistory ORDER BY time ASC; ]]) do
    session_id = false
    if row.bash_pid and row.session_start then
        session_id = row.session_start + row.bash_pid * math.floor(10 ^10)
    elseif row.session_start and not row.bash_pid then
        session_id = row.session_start + 7777 * math.floor(10 ^10)
    elseif not row.session_start and not row.bash_pid then
        session_id = row.lines .. row.columns .. string.sub(row.tty,string.find(row.tty,"%d+"))
    else
       assert(false,"Error, unhandled row:" .. json.encode(row))
    end
    if session_id then
        start = false
        if row.session_start then
            start = row.session_start
        else
            start = tonumber(row.time)
        end
        user = row.user
        if not user and row.pwd and string.match(row.pwd,"^/home") then
            user = string.gsub(row.pwd, "/home/","")
        end
        if not sessions[session_id] then
            sessions[session_id] = {
                session_start=start,
                bash_pid=row.bash_pid,
                ssh_connection=row.ssh_connection,
                tty=row.tty,
                user=user,
                hostname=row.hostname,
                session_id=session_id,
            }
                 session_ins:bind_names(sessions[session_id])
            assert(outdb:errcode(), outdb:errmsg())
            local state = session_ins:step()
            if state == sqlite3.DONE then
                session_ins:reset()
            else
                assert(outdb:errmsg())
            end
            -- print(s_stmt)
        end
        -- print(json.encode(row))
        keys = {}
        values = {}
        for _, n in ipairs({'lines','columns','time','command','pwd','return_value','duration_msec','history_lineno'}) do
            if (row[n]) then table.insert(keys, n) values[n] = row[n] end
        end
        -- r_stmt = [[ INSERT INTO bashhistory (session_id,]] .. table.concat(keys,",") .. 
        --    [[ ) VALUES ( :session_id,:]] .. table.concat(keys, ",:") .. [[)]]
        -- r_ins = outdb:prepare(r_stmt)
        -- assert(r_ins, "\nFailed statement:"..r_stmt.."\nError: "..outdb:errmsg())
        r_ins:bind_names(values)
        assert(outdb:errcode(), outdb:errmsg())
        r_ins:step()
        r_ins:reset()
    else
        assert(false,"no session_id")
    end
    -- stmt = [[INSERT INTO bashhistory time,]]
end

outdb:exec([[COMMIT TRANSACTION;]])
-- print(json.encode(sessions))
