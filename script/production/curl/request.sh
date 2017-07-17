#!/bin/sh
cd ~/git/line-bot-for-basketball-circle
curl -v -X GET https://mgm.basketball.balthazar.tokyo/schedule/request/`cat tmp/token`
