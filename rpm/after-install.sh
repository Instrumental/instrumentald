#!/bin/sh
set -e
chkconfig --add instrumentald
chkconfig instrumentald on
service instrumentald restart
echo "Remember to edit /etc/instrumentald.toml with your Instrumental Project Token"
exit 0
