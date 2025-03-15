help:
	echo hi ho
.PHONY: test
test:
	./test/bats/bin/bats test/inserts.bats
