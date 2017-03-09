#!/bin/sh
set -e

if dpkg -S /sbin/init | grep -q 'sysvinit' || dpkg -S /sbin/init | grep -q 'upstart'
then
  update-rc.d instrumentald defaults
  echo "InstrumentalD will be enabled by default at next reboot"
  echo "To (re)start the daemon, use 'sudo /etc/init.d/instrumentald restart'"
  echo "Remember to edit /etc/instrumentald.toml with your Instrumental Project Token"
elif dpkg -S /sbin/init | grep -q 'systemd'
then
  systemctl enable instrumentald.service
  systemctl start instrumentald
  echo "InstrumentalD will be enabled by default at next reboot"
  echo "To (re)start the daemon, use 'sudo systemctl start instrumentald'"
  echo "Remember to edit /etc/instrumentald.toml with your Instrumental Project Token"
else
  echo "Starting InstrumentalD failed, could not determine whether to use sysvinit or systemd"
fi
exit 0
