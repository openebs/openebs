FROM ubuntu
LABEL maintainer="OpenEBS"
RUN apt-get update
RUN apt-get install -y mysql-client timelimit 
COPY MySQLLoadGenerate.sh /
