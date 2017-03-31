FROM ubuntu:16.04

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
    && apt-get clean


COPY launcher.sh /

CMD ["/launcher.sh"]
