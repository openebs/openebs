#!/bin/bash

KEEP_ALIVE=false
keep_running() {
  while ${KEEP_ALIVE}; 
  do
    echo "Still alive..."
    sleep 10
  done
}

_stop() {
  echo "clearing stuff before stopping.."
  KEEP_ALIVE=false
}

echo "Trapping SIGINT, SIGTERM and SIGKILL"
trap _stop SIGINT
Trap _stop SIGTERM

echo "All is well"
KEEP_ALIVE=true
keep_running


