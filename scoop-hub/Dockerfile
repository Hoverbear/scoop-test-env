# A Dockerfile!
FROM phusion/passenger-ruby19

### Add mongo repo
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
RUN echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | tee /etc/apt/sources.list.d/mongodb.list

### Stuff we need
RUN apt-get update

# Needed for SCOOP
RUN apt-get --yes install ntp libxslt-dev libxml2-dev mongodb-org autossh

### Add Unprivilaged autossh account for tunneling.
# NOTE: Remove `|| true` when https://github.com/dotcloud/docker/issues/6345 is closed.
RUN adduser --disabled-password autossh || true

### ENV and User
USER app
ENV HOME /home/app/

### Install endpoint software.
WORKDIR /home/app
RUN git clone git://github.com/scoophealth/query-composer.git
WORKDIR /home/app/query-composer
RUN bundle install --path vendor/bundle
RUN mkdir -p /home/app/query-composer/tmp/pids # Make PIDS

### Change back to root
USER root

### Setup Mongo
RUN mkdir -p /etc/service/mongodb/ && \
    mkdir -p /data/db && \
    chown -R mongodb /data/db
VOLUME ['/data/db']
ADD scripts/mongodb.sh /etc/service/mongodb/run
RUN chmod +x /etc/service/mongodb/run

ADD scripts/hub.sh /etc/service/hub/run
RUN chmod +x /etc/service/hub/run

### Expose Port
EXPOSE 27017 30308 13001 3002

### Run Command
CMD ["/sbin/my_init"]


###
# Using SELinux?
# --------------
# chcon -Rt svirt_sandbox_file_t $(pwd)/db
###
# Starting
# --------
# NAME="hub-1"
# docker run -d --name=$NAME -p 13001:13001 -p 30308:30308 -p 3002:3002 hub
###
# Backing up the Database
# -----------------------
# PORT=$(docker port $NAME 27017 | awk '{split($0,a,":"); print a[2]}')
# docker run --rm --link $NAME\:target -v $(pwd)/db:/restore mongo mongorestore -p $PORT -h target /restore
###
# Namespace entering
# ------------------
# sudo nsenter --target $(docker inspect --format {{.State.Pid}} $NAME) --mount --uts --ipc --net --pid /bin/bash
###
# In the namespace:
# -----------------
# su app
# cd /home/app/query-composer/
# bundle exec rake hquery:users:grant_admin USER_ID=$USER
###
