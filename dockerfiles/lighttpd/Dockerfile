FROM debian:jessie

RUN apt-get update && apt-get -y install lighttpd
RUN  echo server.network-backend = \"writev\" >> /etc/lighttpd/lighttpd.conf && rm -rf /var/cache/apt/* && \
	sed -i 's/\/var\/www\/html/\/www/g' /etc/lighttpd/lighttpd.conf''

EXPOSE 80
VOLUME /www
CMD ["lighttpd", "-D", "-f", "/etc/lighttpd/lighttpd.conf"]

