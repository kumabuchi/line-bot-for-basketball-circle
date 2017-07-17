#!/bin/sh
cd ~/git/line-bot-for-basketball-circle
curl -v -X GET https://mgm.basketball.balthazar.tokyo/schedule/summary/`cat tmp/token`
