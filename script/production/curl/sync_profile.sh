#!/bin/sh
cd ~/git/line-bot-for-basketball-circle
curl -v -X GET https://mgm.basketball.balthazar.tokyo/schedule/sync/profile/`cat tmp/token`
