#!/bin/bash

while date -Isec; do

  ./run.rb -s 'DC_2020_events.csv' 'DC_2020_links.csv' /mnt/DC_upload/Media/DevConf_2020-processed/DAY_3/*/ 2>&1 \
    | tee -a "logs/upload_`date -Ins`.log"

  echo 'sleeping...'
  sleep 24h
  echo
done

