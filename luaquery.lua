#!/usr/bin/env lua
local os = require("os")
local sqlite3 = require("lsqlite3")



params = {
    separator = '▒░',
    condensed = false,
    powerline = false,
    theme = {}
}
params.theme.timeFg = 254
params.theme.timeBg = 23

params.theme.pathFg = 250
params.theme.pathBg = 237


if ( require("powerline.theme") ) then
    params.powerline = true
    params.theme    = require("powerline.theme")
    exitcode = require("powerline.exitcode")
    duration = require("powerline.duration")
end


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

-- time is stored as sqlite3 juliandate, this converts to unix time *with* decimals:
search = db:prepare([[
SELECT (strftime("%s",time)) as time, command, pwd, return_value, duration_msec, ssh_connection FROM bashhistory WHERE (command GLOB ?) ORDER BY time ASC
]])
if (not (db:errcode() == 0)) then
    print(db:errmsg())
    return 1
end
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

search:bind_values(query)


for row in search:nrows() do
    if (params.powerline) then
        if row.ssh_connection then
            params.ssh = string.match(row.ssh_connection, "%g+")
        end
        params.duration = 0.0001
        if (row.duration_msec) then
            params.duration = (row.duration_msec ) / 1000
        else
            params.duration = 0
        end
        if (row.return_value) then
            params.exitcode = row.return_value
        end
        params.time = row.time
        params.path = row.pwd

        segments = {}
        buffer = ""
        modules = { "time", "duration", "ssh", "path", "exitcode" }
        for _, module in ipairs(modules) do
            mod = require("powerline." .. module)
            modsegments = mod.main(params)
            for k, seg in ipairs(modsegments) do
                if not (seg.text == nil or #seg.text == 0) then
                    table.insert(segments, seg)
                end
            end
        end
        for id,segment in ipairs(segments) do
            if not (id == 1) then
                buffer = buffer .. fgbgColor( segment.background, segments[id-1].background )
                if not params.condensed then
                    buffer = buffer .. " "
                end
                buffer = buffer .. fgbgColor( segments[id-1].background, segment.background)
                buffer = buffer .. params.separator
                if not params.condensed then
                    buffer = buffer .. " "
                end
            end
            buffer = buffer .. fgbgColor( segment.foreground, segment.background)
            buffer = buffer .. segment.text
        end
        buffer = buffer .. reset()
        if not (params.separator == '') then
            buffer = buffer .. fgColor( segments[#segments].background)
            if not params.condensed then
                buffer = buffer .. "█" -- unicode 2588  █ full block
            end
            buffer = buffer .. params.separator
            buffer = buffer .. reset()
        end
    -- finish powerline mode
    else
        buffer =  fgbgColor(theme.timeFg, theme.timeBg) .. os.date(nil, row.time)
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
        buffer = buffer .. reset() .. fgColor(theme.pathBg) .. params.separator .. reset()
    end
    buffer = buffer .."\n" .. row.command
    print(buffer)
end
