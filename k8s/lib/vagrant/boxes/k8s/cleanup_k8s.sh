#!/bin/bash

# Cleaning up apt and bash history before packaing the box. 
sudo apt-get clean
cat /dev/null > ~/.bash_history && history -c && exit