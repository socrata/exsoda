#!/bin/bash

# Simple thing to watch your project and run tests on change
# Takes one optional argument, which will grep tests and run the ones that match

while inotifywait -r -e modify ./lib ./test; do
  echo "Running unit tests"
  mix test
done
