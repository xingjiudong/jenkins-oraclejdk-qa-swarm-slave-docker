FROM openfrontier/jenkins-swarm-maven-slave:oracle-jdk

MAINTAINER XJD <xing.jiudong@trans-cosmos.com.cn>

ENV RUBY_MAJOR=2.3 \
    RUBY_VERSION=2.3.0 \
    BUGSPOTS_VERSION=0.2.1 \
    NODEJS_VERSION=v4.2.6 \
    JQ_VERSION=1.5 \
    SONAR_SCANNER_VERSION=2.6

ENV REGISTRY_HOST=${REGISTRY_URL:-localhost}

USER root

# Install ruby
RUN yum -y install \
    bzip2-devel \
    libffi-devel \
    glib2-devel \
    libjpeg-devel \
    sqlite-devel \
    openssl \
    openssl-devel \
    libxml2-devel \
    libxslt-devel \
    zlib-devel \
    libyaml-devel \
    cmake \
    gcc \
    gcc-c++ \
    make \
    && yum clean all

RUN set -x \
    && curl  -sLo /usr/local/src/ruby-$RUBY_VERSION.tar.gz  "http://cache.ruby-lang.org/pub/ruby/$RUBY_MAJOR/ruby-$RUBY_VERSION.tar.gz" \
    && tar -zxvf /usr/local/src/ruby-$RUBY_VERSION.tar.gz -C /usr/local/src \
    && cd /usr/local/src/ruby-$RUBY_VERSION \
    && ./configure \
    && make \
    && make install

# Install bugspots
RUN gem install bugspots --version=${BUGSPOTS_VERSION}

# nodejs
RUN set -x && mkdir /opt/node && curl -fsSL https://nodejs.org/dist/${NODEJS_VERSION}/node-${NODEJS_VERSION}-linux-x64.tar.gz \
    | tar -xzC /opt/node && \
    ln -s /opt/node/node-${NODEJS_VERSION}-linux-x64 /opt/node/default && \
    /opt/node/default/bin/npm config -g set registry  http://${REGISTRY_HOST}/nexus/content/groups/npm/
# tslint
RUN /opt/node/default/bin/npm config set proxy null && \
    /opt/node/default/bin/npm config set https-proxy null && \
    /opt/node/default/bin/npm config set registry http://registry.npmjs.org/ && \
    /opt/node/default/bin/npm install tslint typescript -g

# jq
RUN set -x && curl -sLo /usr/local/bin/jq https://github.com/stedolan/jq/releases/download/jq-${JQ_VERSION}/jq-linux64 && \
    chmod +x /usr/local/bin/jq

# sonar-scanner
RUN mkdir /opt/sonar-scanner
RUN set -x && curl -sLo /opt/sonar-scanner/sonar-scanner-${SONAR_SCANNER_VERSION}.zip https://sonarsource.bintray.com/Distribution/sonar-scanner-cli/sonar-scanner-${SONAR_SCANNER_VERSION}.zip && \
    unzip -d /opt/sonar-scanner  /opt/sonar-scanner/sonar-scanner-${SONAR_SCANNER_VERSION}.zip && \
    ln -s /opt/sonar-scanner/sonar-scanner-${SONAR_SCANNER_VERSION}/ /opt/sonar-scanner/default && \
    chown -R jenkins:jenkins /opt/sonar-scanner/sonar-scanner-${SONAR_SCANNER_VERSION}/ && \
    rm -f /opt/sonar-scanner/sonar-scanner-${SONAR_SCANNER_VERSION}.zip

ENV SONAR_RUNNER_HOME=/opt/sonar-scanner/default
ENV PATH $PATH:/opt/sonar-scanner/default/bin

USER "${JENKINS_USER}"
