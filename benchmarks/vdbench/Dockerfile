FROM ubuntu:16.04

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        csh \
        default-jre \
    && apt-get clean


COPY vdbench vdbench.jar bench_runner.sh /
COPY linux /linux/
COPY templates /templates/

CMD ["/bench_runner.sh"]
