# lab/Dockerfile
FROM ubuntu:22.04

ENV container docker

RUN apt-get update && apt-get install -y --no-install-recommends \
    systemd \
    systemd-sysv \
    dbus \
    less \
    curl \
    vim \
    strace \
    lsof \
    stress \
    gcc \
    libc6-dev \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Copia os services e o script de boot
COPY faulty.c       /root/faulty.c
COPY faulty.service /etc/systemd/system/
COPY stress.service /etc/systemd/system/
COPY setup.sh /root/setup.sh
RUN chmod +x  /root/setup.sh

VOLUME [ "/sys/fs/cgroup" ]
STOPSIGNAL SIGRTMIN+3

ENTRYPOINT ["/root/setup.sh"]
