#!/bin/bash

nohup sudo -u www-data /opt/tiny_dep/project_update_listen > /var/log/tiny_update_hook.log 2 > /var/log/tiny_update_hook.err &

#start-stop-daemon --start --user www-data --oknodo --pidfile /var/run/tiny.pid --exec /opt/tiny_dep/project_update_listen > /dev/null
