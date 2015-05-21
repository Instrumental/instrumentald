#!/bin/sh
set -e
chkconfig --add instrument_server
chkconfig instrument_server on
service instrument_server start
echo "Remember to edit /etc/instrumental.yml with your Instrumental API key"
exit 0
