#!/usr/bin/env lua
local os = require("os")
local sqlite3 = require("lsqlite3")

local theme = {}

theme.timeFg = 254
theme.timeBg = 23

theme.pathFg = 250
theme.pathBg = 237

params = {
    separator = '▒░',
    condensed = false
}

function fgColor(code)
        return string.format("\27[38;5;%dm", code)
end
function bgColor(code)
        return string.format("\27[48;5;%dm", code)
end
function fgbgColor(fg,bg)
        return string.format("\27[38;5;%d;48;5;%dm", fg, bg )
end
function reset()
        return "\27[0m"
end

local db = assert(sqlite3.open(assert(os.getenv('HISTDB'))))

search = db:prepare([[
SELECT datetime(time) as time, command, pwd FROM bashhistory WHERE (command GLOB ?) ORDER BY time ASC
]])

print(db:errmsg())
print(arg[1])

query = arg[1]

-- Dumb regex compatibility stuff
if not (string.sub(query, 1,1) == "^") then
    query = "*" .. query
else
    query = string.sub(query, 2,-1)
end
if not (string.sub(query, -1,-1) == "$") then
    query = query .. "*"
else
    query = string.sub(query, 1,-2)
end

print(query)
search:bind_values(query)

for row in search:nrows() do
    buffer =  fgbgColor(theme.timeFg, theme.timeBg) .. row.time
    if not params.condensed then
        buffer = buffer .. " "
    end
    buffer = buffer .. fgbgColor(theme.timeBg, theme.pathBg ) .. params.separator
    if not params.condensed then
        buffer = buffer .. " "
    end
    buffer = buffer .. fgbgColor(theme.pathFg, theme.pathBg)  
    if row.pwd then
        buffer = buffer .. row.pwd
    end
    if not params.condensed then
        buffer = buffer .. " "
    end
    buffer = buffer .. reset() .. fgColor(theme.pathBg) .. params.separator .. reset() .."\n" .. row.command
    print(buffer)
end
