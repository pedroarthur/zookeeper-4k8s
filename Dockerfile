FROM ubuntu:trusty

MAINTAINER PEdro Arthur Duarte (aka JEdi)

ENV ZOOKEEPER_VERSION 3.4.9

ENV JAVA_HOME /usr/lib/jvm/java-7-openjdk-amd64

ENV ZK_HOME /opt/zookeeper
ENV ZK_CONF /opt/zookeeper/conf/zoo.cfg
ENV ZK_DATA /opt/zookeeper/data

RUN apt-get update && apt-get install -y unzip openjdk-7-jre-headless wget dnsutils \
      && wget -q http://mirror.vorboss.net/apache/zookeeper/zookeeper-${ZOOKEEPER_VERSION}/zookeeper-${ZOOKEEPER_VERSION}.tar.gz \
      && wget -q https://www.apache.org/dist/zookeeper/KEYS \
      && wget -q https://www.apache.org/dist/zookeeper/zookeeper-${ZOOKEEPER_VERSION}/zookeeper-${ZOOKEEPER_VERSION}.tar.gz.asc \
      && wget -q https://www.apache.org/dist/zookeeper/zookeeper-${ZOOKEEPER_VERSION}/zookeeper-${ZOOKEEPER_VERSION}.tar.gz.md5 \
      && md5sum -c zookeeper-${ZOOKEEPER_VERSION}.tar.gz.md5 \
      && gpg --import KEYS && gpg --verify zookeeper-${ZOOKEEPER_VERSION}.tar.gz.asc \
      && tar -xzf zookeeper-${ZOOKEEPER_VERSION}.tar.gz -C /opt \
      && mv /opt/zookeeper-${ZOOKEEPER_VERSION} ${ZK_HOME} \
      && mv ${ZK_HOME}/conf/zoo_sample.cfg ${ZK_CONF} \
      && sed -i -e '/TRACEFILE/d' -e '/ROLLINGFILE/d' ${ZK_HOME}/conf/log4j.properties \
      && sed -i -e '/#/d' -e '/^\s*$/d' ${ZK_CONF} ${ZK_HOME}/conf/log4j.properties \
      && sed -i -e "s:^dataDir=.*:dataDir=${ZK_DATA}:" ${ZK_CONF} \
      && apt-get clean

WORKDIR ${ZK_HOME}
VOLUME  ${ZK_DATA}

ADD zk-start.sh      /usr/local/bin/zk-start.sh
ADD zk-entrypoint.sh /usr/local/bin/zk-entrypoint.sh

EXPOSE 2181 2888 3888

ENTRYPOINT [ "/usr/local/bin/zk-entrypoint.sh" ]
CMD        [ "/usr/local/bin/zk-start.sh" ]

