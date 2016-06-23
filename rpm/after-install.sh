#!/bin/sh
set -e
chkconfig --add instrumentald
chkconfig instrumentald on
service instrumentald start
echo "Remember to edit /etc/instrumentald.toml with your Instrumental API key"
exit 0
