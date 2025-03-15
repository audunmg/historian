# From here: https://stackoverflow.com/questions/5303553/gnu-make-extracting-argument-to-j-within-makefile
MAKE_PID := $(shell echo $$PPID)
JOBS := $(shell ps T | sed -n 's%.*$(MAKE_PID).*$(MAKE).* \(-j\|--jobs=\) *\([0-9][0-9]*\).*%\2%p')



help:
	echo hi ho

.PHONY: test test_query test_insert
test: test_query test_insert

test_query:
	./test/bats/bin/bats --tap test/query.bats -j $(JOBS) 
test_insert:
	./test/bats/bin/bats --tap test/inserts.bats -j $(JOBS)
