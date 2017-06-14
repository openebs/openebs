#! /bin/sh

MySQLDump()
{
while true
do
 mysql -uroot -pk8sDem0 -h $pod_ip -e "INSERT INTO Hardware select * FROM Hardware;" Inventory
 sleep 2
done
}

PrepareMySQL()
{
mysql -uroot -pk8sDem0 -h $pod_ip -e "CREATE DATABASE Inventory;"

mysql -uroot -pk8sDem0 -h $pod_ip -e \
"CREATE TABLE Hardware (Name VARCHAR(20),HWtype VARCHAR(20),Model VARCHAR(20));" Inventory 

mysql -uroot -pk8sDem0 -h $pod_ip -e \
"INSERT INTO Hardware (Name,HWtype,Model) VALUES ('TestBox','Server','DellR820');" Inventory
}

pod_ip=$1
PrepareMySQL;
MySQLDump; 

