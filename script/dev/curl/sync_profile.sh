#!/bin/sh
cd ~/git/line-bot-for-dev
curl -v -X GET https://dev.basketball.balthazar.tokyo/schedule/sync/profile/`cat tmp/token`
