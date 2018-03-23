#!/bin/bash

mysql -uroot -pk8sDem0 -e "CREATE DATABASE Inventory;"
mysql -uroot -pk8sDem0 -e "CREATE TABLE Hardware (id INTEGER, name VARCHAR(20), owner VARCHAR(20),description VARCHAR(20));" Inventory
mysql -uroot -pk8sDem0 -e "INSERT INTO Hardware (id, name, owner, description) values (1, "dellserver", "basavaraj", "controller");" Inventory
mysql -uroot -pk8sDem0 -e "DROP DATABASE Inventory;"
