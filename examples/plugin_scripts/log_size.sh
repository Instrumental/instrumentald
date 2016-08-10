ls -s --block-size=1 /var/log | grep '.*\.log$' | grep -o '.*[^.log]' | awk '{ print "hostname.log_size." $2 " " $1}' | sed 's/hostname/'"`hostname`"'/g'
