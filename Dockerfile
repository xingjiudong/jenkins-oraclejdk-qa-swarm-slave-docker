FROM xingjiudong/jenkins-oraclejdk-swarm-maven-slave

MAINTAINER XJD <xing.jiudong@trans-cosmos.com.cn>

USER root
RUN set -ex \
        && yum install -y \
                bison \
                dpkg-dev \
                libgdbm-dev \
                libssl1.0-dev \
                gcc \
                cmake \
                ruby-dev \
                pkg-config \
                make \
                ruby \

RUN gem install bugspots

USER "${JENKINS_USER}"

