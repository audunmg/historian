source test/common-stuff.sh

@test "Insert script runs" {
    run_luains
}

@test "Create tables" {
    create_tables
    run sqlite3 $HISTDB -- .dump
    assert_line --partial "CREATE TABLE bashhistory"
    assert_line --partial "CREATE TABLE bashsession"
}

@test "Insert session" {
    export SSH_CONNECTION="127.0.0.1 12345 127.0.0.1 22"
    export TTY="/dev/testtty"
    create_tables
    echo Inserting session
    source historian.bash
    echo Session inserted
    session="$(sqlite3 -json $HISTDB -- "SELECT * FROM bashsession;")"
    for n in session_id session_start bash_pid; do 
	echo Check "${n}"
	assert [ "$(jq -r ".[0].${n}" <<< $session)" -gt 1 ]
    done

    for n in ssh_connection tty user hostname; do 
	local p="${n^^}"
        echo "Check ${n^^}"
	assert_equal "$(jq -r ".[0].$n" <<< $session)" "${!p}"
    done
}

@test "Insert line" {
    create_tables
    source historian.bash
    export COLUMNS=1023
    export LINES=101
    export READLINE_LINE="This is the test command to be inserted"
    export HISTORY_LINE=1
    # PWD is read by the insert, but is already defined so no need to mess
    run_luains insert
    line="$(sqlite3 -json $HISTDB -- "SELECT * FROM bashhistory;")"
    # Check variables with same (except lowercase) sql name as env var:
    for n in lines columns "pwd"; do 
	local p="${n^^}"
        echo "Check ${n^^}"
	assert_equal "$(jq -r ".[0].$n" <<< $line)" "${!p}"
    done

    echo Check Command
    assert_equal "$(jq -r ".[0].command" <<< $line)" "$READLINE_LINE"
    echo Check Line number
    assert_equal "$(jq -r ".[0].history_lineno" <<< $line)" "$HISTORY_LINE"

    echo Check duration for null
    assert_equal "$(jq -r ".[0].duration_msec" <<< $line)" "null"

    echo Check return_value for null
    assert_equal "$(jq -r ".[0].return_value" <<< $line)" "null"

    echo Check if time makes sense
    sleep 0.1
    assert [ "$(jq -r ".[0].time * 10000000 | floor" <<< $line)" -lt "$(sqlite3 $HISTDB -- "SELECT cast ((select julianday('now')*10000000) as integer);" )" ]
}

@test "Update line" {
    create_tables
    source historian.bash
    export READLINE_LINE="This is the test command to be inserted"
    export HISTORY_LINE=1
    # PWD is read by the insert, but is already defined so no need to mess
    run_luains insert
    RETURN_VALUE=1024
    DURATION_MSEC=123
    _historian_update $RETURN_VALUE $DURATION_MSEC $HISTORY_LINE
    line="$(sqlite3 -json $HISTDB -- "SELECT * FROM bashhistory;")"
    for n in return_value duration_msec; do 
	local p="${n^^}"
        echo "Check ${n^^}"
	assert_equal "$(jq -r ".[0].$n" <<< $line)" "${!p}"
    done
    echo Check Line number
    assert_equal "$(jq -r ".[0].history_lineno" <<< $line)" "$HISTORY_LINE"

}


 

