#!/bin/sh
set -e
chkconfig --add instrumentald
chkconfig instrumentald on
service instrumentald start
echo "Remember to edit /etc/instrumental.yml with your Instrumental API key"
exit 0
