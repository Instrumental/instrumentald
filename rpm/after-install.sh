#!/bin/sh
set -e
chkconfig --add instrumentald
chkconfig instrumentald on

echo "Remember to edit /etc/instrumentald.toml with your Instrumental Project Token"
echo "InstrumentalD will be enabled by default at next reboot"
echo "To (re)start the daemon, use 'sudo service instrumentald restart'"
exit 0
