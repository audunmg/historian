#!/usr/bin/env lua
-- c-basic-offset: 4; tab-width: 4; indent-tabs-mode: nil
-- vi: set shiftwidth=4 tabstop=4 expandtab:
-- :indentSize=4:tabSize=4:noTabs=true:

-- file = io.open('fifo', 'r')

sql = require('lsqlite3')


activesession = true
pwd = ''
basedir = '/home/audunmg/.local/share/historian'

for k,v in ipairs(arg) do
    if (v == "-s") or (v == "--session-id") then
        session_id = tonumber(arg[k+1])
    end if (v == "-f") or (v == '--file') then
        database_file = arg[k+1]
    end
end

local function insertcmd(time, command)
    local db = sql.open(database_file)
    -- print(string.format("time: %d\ncomm: %s\npwd: %s", time, command, pwd))
    local insert_cmd = assert( db:prepare("INSERT INTO history (session_id, time, command, pwd) VALUES (:session_id, :time, :command, :pwd)"))
    insert_cmd:bind_values(session_id, time, command, pwd)
    insert_cmd:step()
    insert_cmd:finalize()
    db:close()
end










while (activesession) do
    file = io.open(string.format("%s/sessions/%s", basedir, session_id), 'r')
    line = file:read("*a")
    file:close()
    if (not(line == nil)) then
        print(line)
        if (string.sub(line, 0, 1) == "#") then
            for time, command in line:gmatch('#(%d+)\n(.*)\n') do
                -- print(string.format("time: %d\ncommand: %s\nend", time, command))
                insertcmd(time,command)
            end
        else
            for key, val in line:gmatch('([^=]+)=(%g+)\n') do
                if (key == 'pwd') then
                    pwd = val
                end
                -- print(string.format("%s %s", key, val))
                if (key == 'exit') then
                    os.exit(0)
                end
            end
        end
    end
end
