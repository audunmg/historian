#!/usr/bin/env lua

local os = require("os")
local posix = require("posix")
local sqlite3 = require("lsqlite3")

function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end



-- local db = assert(sqlite3.open(assert(os.getenv('HISTDB')),sqlite3.OPEN_READONLY ))
local db = assert(sqlite3.open(assert(os.getenv('HISTDB')) ))

sessions = {}
for row in db:nrows("SELECT DISTINCT session_start FROM bashhistory WHERE (pwd IS NULL) AND command GLOB '*cd*' AND hostname IS '" .. os.getenv('HOSTNAME') .. "';") do 
    table.insert(sessions, row.session_start)
end

-- sessions = {1644145080}
-- sessions = {1642555440}
-- sessions = { 1444297740 }
for _,session in ipairs(sessions) do 
    print("------------------ "..session.." --------------")
    session_pwd = ""
    posix.chdir(os.getenv('HOME'))
    failure = false
    for row in db:nrows("SELECT id,session_start,command FROM bashhistory WHERE session_start IS '" .. session .. "';") do 
        if row.command == "cd" then
            session_pwd = os.getenv('HOME')
            failure = false
        end
        if not failure then
            row["pwd"] = session_pwd
            local dir = string.match(row.command, "^cd ([^ ]*)")
            if (dir) then
                local dir =  string.gsub(string.match(row.command, "^cd ([^ ]*)"), '/$', '')
                local cpwd = ""
                if session_pwd == "" then
                    cpwd = os.getenv('HOME')
                end
                if string.match(dir, "^/") then
                    test = posix.stat(dir)
                else
                    test = posix.stat(dir)
                    -- test = posix.stat(cpwd .. "/" .. dir)
                end
                if test ~= nil and test.type == 'directory' then
                    print(dir)
                    if session_pwd == "" then
                        -- command = "BEGIN TRANSACTION;"
                        command = ""
                        -- for backrow in db:nrows("SELECT id FROM bashhistory WHERE session_start IS " .. row.session_start .. " AND id <= ".. row.id ) do 
                        command = command .. "UPDATE bashhistory SET pwd = '" .. os.getenv('HOME') .. "' WHERE ( session_start IS "..row.session_start .. " AND id <= " .. tostring(row.id) ..");"
                        -- end
                        -- command = command .. "COMMIT;"
                        print(command)
                        db:exec(command)
                        print(db:errmsg())
                        row["pwd"] = os.getenv('HOME')
                    end
                    posix.chdir(dir)
                    session_pwd = posix.getcwd()
                else
                    print("Failed")
                    failure = true

                end
            end
            db:exec("UPDATE bashhistory SET pwd = '" .. row.pwd .. "' WHERE id IS " .. row.id )
            print(row.id, row.pwd .. "," .. row.command)
        end
    end
end
