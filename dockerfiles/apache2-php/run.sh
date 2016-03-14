#!/bin/bash

chown www-data.www-data /www -R
/usr/sbin/apache2ctl -DFOREGROUND
