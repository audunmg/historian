#!/usr/bin/env lua
local os = require("os")
local posix = require("posix")
local sqlite3 = require("lsqlite3")

--- This function checks if the session is still running:
function bashpid(pid, session_start, tty)
    foreground = 232
    thisbackground  = 227
    runningbackground = 47
    text = "▲"
    if pid == nil or session_start == nil then return nil end
    if (pid == tonumber(os.getenv('BASH_PID')) and session_start == tonumber(os.getenv('SESSION_START')) ) then
        -- Session running in this terminal
        return {
            foreground = foreground,
            background = thisbackground,
            text = text
        }
    end
    local f=io.open("/proc/" .. pid .."/comm","r")
    if f~=nil then
        if(f.read(f) == "bash" and session_start == posix.stat("/proc/" .. pid).ctime ) then
            io.close(f)
            -- Session running in other terminal
            return {
            foreground = foreground,
            background = runningbackground,
            text = tty
            }
        else
            io.close(f)
        end
    end
    -- Not running
    return nil
end

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

function usage()
    print(arg[0] .. " [-h] [-p] [-e regex-query] [-S SQL-query] [-r] [-s sort_col]")
end

function help()
    usage()
    print([[

    -p                          Search for history in current directory (think pwd)
    -e, --query regex-query     Search by matching command to regex-query
    -S, --sql-query SQL-query   Search with custom SQL query
    -r, --reverse               Reverse sorting
    -s, --sort                  Sort by column
    -h, --help                  This help

    ]])
end

local db = assert(sqlite3.open(assert(os.getenv('HISTDB')),sqlite3.OPEN_READONLY ))

if (not (db:errcode() == 0)) then
    print(db:errmsg())
    os.exit(1)
end


search = ""
search_names = {}
search_expr = {}
sort_order = "ASC"
sort_by    = "time"
for k,v in ipairs(arg) do
    if (v == '-h') or (v == '--help') then
        help()
        os.exit(0)
    elseif (v == '-c') or (v == '-d') then
        usage()
        print ("Clear or delete history not supported")
        os.exit(2)
    elseif (v == '-p') then
        table.insert(search_expr, '(pwd IS :PWD)')
        search_names['PWD'] = os.getenv('PWD')
    elseif (v == '-e') or (v == '--query') then
        query = assert(arg[k+1])
        table.insert(search_expr, '(command REGEX :QUERY)')
        search_names['QUERY'] = query
    elseif (v == '-S') or (v == '--sql-query') then
        sqlquery = assert(arg[k+1])
        table.insert(search_expr, '('.. sqlquery ..')')
    elseif (v == '-r') or (v == '--reverse') then
        sort_order = "DESC"
    elseif (v == '-s') or (v == '--sort') then
        sort_by = assert(arg[k+1])
    end
end

if (#search_expr == 0) then
    search_expr = {"session_start IS :session_start AND bash_pid IS :bash_pid"}
    search_names = {session_start = os.getenv('SESSION_START'), bash_pid = os.getenv('BASH_PID')}
end


search = db:prepare([[
                SELECT 
                (strftime('%s',time)) as time,
                command,
                pwd,
                return_value,
                duration_msec,
                ssh_connection,
                bash_pid,
                session_start,
                history_lineno,
                tty,
                hostname FROM bashhistory LEFT JOIN bashsession USING (session_id) 
                WHERE (]] .. table.concat(search_expr, " AND ") .. ") ORDER BY "..sort_by.." ".. sort_order ..";")
assert(db:errcode(), db:errmsg())
search:bind_names(search_names)
assert(db:errcode(), db:errmsg())

start_params = params

for row in search:nrows() do
    params.duration = nil
    params.ssh = nil
    params.exitcode = nil
    params.hostname = nil

    if (params.powerline) then
        if row.pwd == nil then
            row.pwd = ''
        end
        -- start powerline mode
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
        -- Segments which are not modules
        local seg_pid = bashpid(row.bash_pid, row.session_start, row.tty)
        if seg_pid ~= nil then table.insert(segments, seg_pid) end

        -- segments which are modules
        modules = { "time", "duration", "ssh", "path", "exitcode" }
        if row.hostname ~= nil and row.hostname ~= os.getenv('HOSTNAME') then
            params.hostname = row.hostname
            table.insert(modules, 2, 'hostname')
        end
        for _, module in ipairs(modules) do
            mod = require("powerline." .. module)
            modsegments = mod.main(params)
            for k, seg in ipairs(modsegments) do
                if not (seg.text == nil or #seg.text == 0) then
                    table.insert(segments, seg)
                end
            end
        end
        -- render segments
        buffer = ""
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
