#!/bin/bash

if [ "$1" = "dev" ]; then
	cp Dockerfile1 Dockerfile
	docker build -t tinystime/php-apache2 .
else
	cp Dockerfile2 Dockerfile
	docker build -t tinystime/php-apache2 .
fi
