FROM alpine

RUN apk add --update lighttpd && rm -rf /var/cache/apk/* && \
	sed -i 's/\/var\/www\/localhost/\/www/g' /etc/lighttpd/lighttpd.conf
EXPOSE 80
VOLUME /var/www/localhost/htdocs
CMD ["lighttpd", "-D", "-f", "/etc/lighttpd/lighttpd.conf"]

