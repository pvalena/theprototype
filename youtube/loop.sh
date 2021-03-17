#!/bin/bash

while date -Isec; do

  ./run.rb -s 'DC_2021_events.csv' 'DC_2021_links.csv' "/run/media/lpcs/Seagate Expansion Drive/Media/DevConfCZ_2021-processed/upload"
   2>&1 \
    | tee -a "logs/upload_`date -Ins`.log"

  echo 'sleeping...'
  sleep 12h
  echo
done

