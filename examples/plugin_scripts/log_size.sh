ls -s --block-size=1 /var/log | grep '.*\.log$' | grep -o '.*[^.log]' | awk '{ print $2 " " $1}'
