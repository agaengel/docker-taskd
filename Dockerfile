FROM debian:8
MAINTAINER Jens Erat <email@jenserat.de>

# Remove SUID programs
RUN for i in `find / -perm +6000 -type f 2>/dev/null`; do chmod a-s $i; done

# Taskd user, volume and port, logs
RUN addgroup --gid 53589 taskd && \
    adduser --uid 53589 --gid 53589 --disabled-password --gecos "taskd" taskd && \
    usermod -L taskd && \
    mkdir -p /var/taskd && \
    chmod 700 /var/taskd && \
    ln -sf /dev/stdout /var/log/taskd.log && \
    chown taskd:taskd /var/taskd /var/log/taskd.log
VOLUME /var/taskd
EXPOSE 53589

# Fetch taskd and dependencies, build and install taskd, remove build chain and source files
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends git ca-certificates build-essential cmake gnutls-bin libgnutls28-dev uuid-dev && \
    cd /opt && \
    git clone -b v1.1.0 --single-branch --depth 1 https://github.com/GothenburgBitFactory/taskserver.git && \
    cd /opt/taskserver && \
    cmake . && \
    make && \
    make install  && \
    rm -rf /opt/taskd && \
    DEBIAN_FRONTEND=noninteractive apt-get remove -y --auto-remove git build-essential cmake && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY taskd.sh /opt/taskd.sh
USER taskd
CMD /opt/taskd.sh
