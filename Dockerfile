FROM openjdk:8-slim
MAINTAINER 1904labs "https://github.com/1904labs/docker-spark"

ARG INSTALL_BASE=/opt
ARG SPARK_UID=185
ARG SPARK_GID=185
# 2.4.6 or 3.0.0
ARG SPARK_VERSION=3.0.0
# 2.7 or 3.2
ARG HADOOP_VERSION=3.2

ENV SPARK_NAME=spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}
ENV SPARK_HOME=${INSTALL_BASE}/${SPARK_NAME}
ENV PATH=$PATH:${SPARK_HOME}/bin

WORKDIR ${INSTALL_BASE}

# install req packages
RUN set -ex && \
    apt-get update && \
    apt-get install -y curl tini libc6 krb5-user libnss3 python3 python3-setuptools && \
    echo "auth required pam_wheel.so use_uid" >> /etc/pam.d/su && \
    chgrp root /etc/passwd && chmod ug+rw /etc/passwd && \
    rm -rf /var/cache/apt/*
   

# Install hadoop and spark
RUN set -ex && \
    curl -sSL https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/${SPARK_NAME}.tgz | tar xzv 

RUN set -ex && \
    groupadd -g ${SPARK_GID} spark && \
    useradd -u ${SPARK_UID} -g ${SPARK_GID} -Md ${SPARK_HOME} -s /bin/false spark && \
    sed 's/set -ex/set -e/' ${SPARK_HOME}/kubernetes/dockerfiles/spark/entrypoint.sh > /opt/entrypoint.sh && \
    chmod +x /opt/entrypoint.sh && \
    mkdir -p ${SPARK_HOME}/work-dir && \
    ln -s ${SPARK_HOME} ${INSTALL_BASE}/spark && \
    chown -R ${SPARK_UID}:${SPARK_GID} ${SPARK_HOME} 

USER ${SPARK_UID}
WORKDIR ${SPARK_HOME}/work-dir
ENTRYPOINT [ "/opt/entrypoint.sh" ]

