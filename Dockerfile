FROM ubuntu:16.04

RUN apt-get update && \
    apt-get -y install make && \
    apt-get -y install python3-pip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
    
RUN pip3 install pipenv
RUN LC_ALL=C.UTF-8 LANG=C.UTF-8 pipenv install codespell
RUN LC_ALL=C.UTF-8 LANG=C.UTF-8 pipenv lock
