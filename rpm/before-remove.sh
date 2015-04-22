#!/bin/sh
set -e
service instrument_server stop
chkconfig instrument_server off
exit 0
