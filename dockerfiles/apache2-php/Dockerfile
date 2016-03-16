FROM debian:jessie
# Install modules
RUN apt-get update && apt-get -y install php5 php5-curl php5-gd php5-mysql && apt-get clean
ADD entrypoint.sh /
RUN bash /entrypoint.sh && rm /entrypoint.sh
COPY default.conf /etc/apache2/sites-available/000-default.conf
COPY run.sh /

EXPOSE 80

RUN userdel www-data && useradd www-data
CMD ["/bin/bash", "/run.sh"]
