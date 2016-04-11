#!/bin/bash

if [ "$1" = "dev" ]; then
	gsed -i 's/# RUN userdel www-data/RUN userdel www-data/g' Dockerfile
	docker build -t tinystime/apache2-laravel:dev .
else
	sed -i 's/^RUN userdel www-data/# RUN userdel www-data/g' Dockerfile
	docker build -t tinystime/apache2-laravel .
fi
