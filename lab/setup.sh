#!/bin/bash
set -e

# Compilar o service e adicionando binario de exec.
gcc lab-solver-full-updated.c -o /usr/local/bin/lab-solver-full
chmod +x /usr/local/bin/lab-solver-full

# Permite o systemd dentro do container
exec /sbin/init
systemctl daemon-reload
systemctl enable --now faulty
systemctl start stress
systemctl start faulty
