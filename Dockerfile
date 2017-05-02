FROM ubuntu:trusty

MAINTAINER PEdro Arthur Duarte (aka JEdi)

ENV ZOOKEEPER_VERSION 3.4.9

ENV JAVA_HOME /usr/lib/jvm/java-7-openjdk-amd64/
ENV JAVA_HOME /usr/lib/jvm/java-7-openjdk-amd64
ENV ZK_HOME   /opt/zookeeper-${ZOOKEEPER_VERSION}

RUN apt-get update && apt-get install -y unzip openjdk-7-jre-headless wget dig \
      && wget -q http://mirror.vorboss.net/apache/zookeeper/zookeeper-${ZOOKEEPER_VERSION}/zookeeper-${ZOOKEEPER_VERSION}.tar.gz \
      && wget -q https://www.apache.org/dist/zookeeper/KEYS \
      && wget -q https://www.apache.org/dist/zookeeper/zookeeper-${ZOOKEEPER_VERSION}/zookeeper-${ZOOKEEPER_VERSION}.tar.gz.asc \
      && wget -q https://www.apache.org/dist/zookeeper/zookeeper-${ZOOKEEPER_VERSION}/zookeeper-${ZOOKEEPER_VERSION}.tar.gz.md5 \
      && md5sum -c zookeeper-${ZOOKEEPER_VERSION}.tar.gz.md5 \
      && gpg --import KEYS && gpg --verify zookeeper-${ZOOKEEPER_VERSION}.tar.gz.asc \
      && tar -xzf zookeeper-${ZOOKEEPER_VERSION}.tar.gz -C /opt \
      && mv /opt/zookeeper-${ZOOKEEPER_VERSION}/conf/zoo_sample.cfg /opt/zookeeper-${ZOOKEEPER_VERSION}/conf/zoo.cfg \
      && sed -i -e '/TRACEFILE/d' -e '/ROLLINGFILE/d' -e '/#/d' -e '/^\s*$/d' /opt/zookeeper-${ZOOKEEPER_VERSION}/conf/log4j.properties \
      && apt-get clean

WORKDIR /opt/zookeeper-${ZOOKEEPER_VERSION}
VOLUME  [ "/tmp/zookeeper" ]

ADD zk-start.sh      /usr/local/bin/zk-start.sh
ADD zk-entrypoint.sh /usr/local/bin/zk-entrypoint.sh

EXPOSE 2181 2888 3888

ENTRYPOINT [ "bash", "/usr/local/bin/zk-entrypoint.sh" ]
CMD        [ "bash", "/usr/local/bin/zk-startk.sh" ]

