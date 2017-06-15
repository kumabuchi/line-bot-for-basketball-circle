#!/bin/sh
cd ~/git/line-bot-for-dev
# 起動中の場合は停止
kill -KILL `cat tmp/pids/unicorn.pid`
sleep 3
bundle exec unicorn -c config/unicorn.rb -E development -D
