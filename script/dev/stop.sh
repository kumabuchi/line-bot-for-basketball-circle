#!/bin/sh
cd ~/git/line-bot-for-dev
# 起動中の場合は停止
kill -0 `cat tmp/pids/unicorn.pid` > /dev/null 2>&1
if [ $? = 0 ]; then
  kill -QUIT `cat tmp/pids/unicorn.pid`
fi
