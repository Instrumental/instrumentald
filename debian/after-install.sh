#!/bin/sh
set -e
update-rc.d instrument_server defaults
/etc/init.d/instrument_server start
echo "Remember to edit /etc/instrumental.yml with your Instrumental API key"
exit 0
