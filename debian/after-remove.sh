#!/bin/sh
set -e
if dpkg -S /sbin/init | grep -q 'sysvinit'
then
  update-rc.d -f instrumentald remove
elif dpkg -S /sbin/init | grep -q 'systemd'
then
  systemctl disable instrumentald.service
fi
exit 0
