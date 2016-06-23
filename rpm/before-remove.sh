#!/bin/sh
set -e
service instrumentald stop
chkconfig instrumentald off
exit 0
