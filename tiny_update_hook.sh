#!/bin/bash

# 干掉运行中的程序
ps -aux |grep project_update_listen|grep -v grep |awk '{print $2}' |xargs kill -9

nohup sudo -u www-data /opt/tiny_dep/project_update_listen 2 > /var/log/tiny_update_hook.err 1 > /var/log/tiny_update_hook.log &

#start-stop-daemon --start --user www-data --oknodo --pidfile /var/run/tiny.pid --exec /opt/tiny_dep/project_update_listen > /dev/null
