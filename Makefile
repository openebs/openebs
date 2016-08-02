.PHONY: all deps test

all: deps test

test:
	go test ./...

deps:
	go get -t ./...
	go get -u github.com/golang/lint/golint

test:
	go test -tags experimental -race -cover ./...

