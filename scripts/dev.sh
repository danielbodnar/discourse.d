#!/bin/bash
set -euo pipefail

# Helper script for development tasks

usage() {
    echo "Usage: $0 {start|stop|build|test|shell|clean}"
    exit 1
}

start() {
    docker-compose up -d
}

stop() {
    docker-compose down
}

build() {
    docker-compose exec dev ./build.sh build "$@"
}

test() {
    docker-compose exec dev ./build.sh test "$@"
}

shell() {
    docker-compose exec dev bash
}

clean() {
    docker-compose down -v
    rm -rf build/* output/*
}

case "${1:-}" in
    start) start ;;
    stop) stop ;;
    build) shift; build "$@" ;;
    test) shift; test "$@" ;;
    shell) shell ;;
    clean) clean ;;
    *) usage ;;
esac