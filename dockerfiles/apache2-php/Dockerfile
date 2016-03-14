FROM debian:jessie
# Install modules
RUN apt-get update && apt-get -y install php5 php5-curl php5-gd php5-redis php5-mysql && apt-get clean
ADD entrypoint.sh /
RUN bash /entrypoint.sh && rm /entrypoint.sh

EXPOSE 80
RUN userdel www-data && useradd www-data
CMD ["/usr/sbin/apache2ctl", "-DFOREGROUND"]
