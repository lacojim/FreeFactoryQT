#!/bin/bash
# FreeFactoryNotifyRunner.sh
# Watches drop folders recursively and feeds events to FreeFactoryNotify.sh
# This is controlled by freefactory-notify.service

/usr/bin/inotifywait -m -r -e close_write,moved_to --format '%w %e %f' \
  /video/dropbox | /opt/FreeFactory/bin/FreeFactoryNotify.sh
