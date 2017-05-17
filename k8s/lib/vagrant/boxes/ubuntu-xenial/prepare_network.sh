#!/bin/bash

# For ubuntu/xenial64 boxes created via vagrant
# /etc/resolv.conf is set with nameserver as 10.0.2.3
# Change this to 127.0.0.1

sudo sed -i "s/10\.0\.2\.3/8\.8\.8\.8/g" /etc/resolv.conf
sudo sed -i "s/cbblr\.com/domain\.name/g" /etc/resolv.conf

