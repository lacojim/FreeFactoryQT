#!/bin/bash
# FreeFactoryNotifyRunner.sh
# Watches drop folders recursively and feeds events to FreeFactoryNotify.sh
# This is raun from the freefactory-notify.service

# FORMAT: 4 fields time|dir|event|file

/usr/bin/inotifywait -m -r -e close_write,moved_to --timefmt '%F %T' --format '%T|%w|%e|%f' --exclude '\.swp$' --exclude '~$' --exclude '\.tmp$' --exclude '\.part$' --exclude '\.crdownload$' --exclude '\.kate-swp$' --exclude '\.DS_Store$' \
  "/video/dropbox" \
| /opt/FreeFactory/bin/FreeFactoryNotify.sh
