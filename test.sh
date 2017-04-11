#!/bin/bash

# Simple thing to watch your project and run tests on change
# Takes one optional argument, which will grep tests and run the ones that match

if [ -z "${SOCRATA_USER}" ] || [ -z "${SOCRATA_PASSWORD}" ]; then
    echo "\$SOCRATA_USER and \$SOCRATA_PASSWORD are required!"
    echo "Please set them in your environment!"
    exit 1
fi

echo "Installing dependencies"
mix deps.get || exit "$1"

if [ -x "$(which inotifywait)" ]; then
    while inotifywait -r -e modify ./lib ./test; do
        echo "Running unit tests"
        mix test
    done
else
    echo "Running unit tests"
    mix test
fi
