# Dependencies:
if !( command -v jq > /dev/null && command -v sqlite3 > /dev/null); then
    echo "Missing deps"
    exit 1;
fi

setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'

    TEMP_DIR="$( mktemp -d tests.XXXXXXX )"
    export HISTDB="$TEMP_DIR"/test.db
}

teardown() {
    rm -r "$TEMP_DIR"
}

run_luains() {
    export BASH_PID=$$
    ./luains.lua $1
}

create_tables() {
    run_luains setup
    echo Created tables
}
