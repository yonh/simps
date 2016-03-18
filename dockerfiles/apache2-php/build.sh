#!/bin/bash

if [ "$1" = "dev" ]; then
	sed -i 's/# RUN userdel www-data/RUN userdel www-data/g' Dockerfile
	docker build -t tinystime/php-apache2:dev .
else
	sed -i 's/^RUN userdel www-data/# RUN userdel www-data/g' Dockerfile
	docker build -t tinystime/php-apache2 .
fi
