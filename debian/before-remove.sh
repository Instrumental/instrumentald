#!/bin/sh
set -e
if dpkg -S /sbin/init | grep -q 'sysvinit'
then
  /etc/init.d/instrumentald stop
elif dpkg -S /sbin/init | grep -q 'systemd'
then
  systemctl stop instrumentald
fi
exit 0
