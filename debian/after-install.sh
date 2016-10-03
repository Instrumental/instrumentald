#!/bin/sh
set -e
update-rc.d instrumentald defaults
/etc/init.d/instrumentald restart
echo "Remember to edit /etc/instrumentald.toml with your Instrumental Project Token"
exit 0
