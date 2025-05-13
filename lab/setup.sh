#!/bin/bash
set -e

gcc /root/faulty.c -o /usr/local/bin/faulty
chmod +x /usr/local/bin/faulty
/sbin/init &
sleep 5
systemctl daemon-reload
systemctl enable faulty.service
systemctl enable stress.service
systemctl start faulty.service
systemctl start stress.service
tail -f /dev/null
