#!/bin/bash
set -e

# Compilar o service e adicionando binario de exec.
gcc /root/faulty.c -o /usr/local/bin/faulty
chmod +x /usr/local/bin/faulty

# Permite o systemd dentro do container
exec /sbin/init
systemctl daemon-reload
systemctl enable --now faulty
systemctl start stress.service
systemctl start faulty.service
