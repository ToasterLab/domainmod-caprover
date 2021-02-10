FROM php:8.0.2-apache
ENV LOCALE="en_US.UTF-8"
ENV DB_HOSTNAME=$DB_HOSTNAME
ENV DB_NAME=$DB_NAME
ENV DB_USERNAME=$DB_USERNAME
ENV DB_PASSWORD=$DB_PASSWORD
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf
RUN apt-get update \
    && apt-get install -y cron curl gettext git libxml2 libxml2-dev locales tzdata \
    && apt-get clean -y \
    && docker-php-ext-install gettext mysqli pdo pdo_mysql simplexml
RUN cp /usr/share/zoneinfo/Asia/Singapore /etc/localtime \
    && echo "Asia/Singapore" > /etc/timezone
COPY domainmod/php.ini-production /usr/local/etc/php/php.ini
COPY domainmod/cron /etc/cron.d/cron
RUN chmod 0644 /etc/cron.d/cron
RUN crontab /etc/cron.d/cron
RUN mkdir -p /var/log/cron
RUN sed -i 's/^exec /service cron start\n\nexec /' /usr/local/bin/apache2-foreground
RUN sed -i -e "s/# $LOCALE/$LOCALE/" /etc/locale.gen
RUN locale-gen
RUN echo "LANG=$LOCALE" > /etc/default/locale
ENV LANG $LOCALE
ENV LC_ALL $LOCALE
RUN cd /var/www/html \
    && git clone https://github.com/domainmod/domainmod.git . \
    && git pull
RUN echo "<?php" \
    "\$web_root='';" \
    "\$dbhostname='${DB_HOSTNAME}}';" \
    "\$dbname='${DB_NAME}';" \
    "\$dbusername='${DB_USERNAME}';" \
    "\$dbpassword='${DB_PASSWORD}';" \
    "?>" \
    >> /var/www/html/_includes/config.inc.php 
RUN chmod 777 /var/www/html/temp
RUN service apache2 restart
EXPOSE 80 443
