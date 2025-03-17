source test/common-stuff.sh


@test "Query script runs" {
    create_tables
    ./luaquery.lua
}

@test "Search by PWD" {
    create_tables
    source historian.bash
    export COLUMNS=1023
    export LINES=101
    export READLINE_LINE="This is the test command to be inserted"
    export HISTORY_LINE=1
    # PWD is read by the insert, but is already defined so no need to mess
    run_luains insert
    run ./luaquery.lua -p
    assert_line --partial "$PWD"
}

@test "Search by Regex" {
    create_tables
    source historian.bash
    export COLUMNS=1023
    export LINES=101
    export READLINE_LINE="This is the test command to be inserted"
    export HISTORY_LINE=1
    # PWD is read by the insert, but is already defined so no need to mess
    run_luains insert
    run ./luaquery.lua -e ^This
    assert_line --partial "This"
}
