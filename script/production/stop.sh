#!/bin/sh
cd ~/git/line-bot-for-basketball-circle
# 起動中の場合は停止
kill -KILL `cat tmp/pids/unicorn.pid`
