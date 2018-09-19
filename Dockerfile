FROM xingjiudong/jenkins-oraclejdk-swarm-maven-slave

MAINTAINER XJD <xing.jiudong@trans-cosmos.com.cn>

USER root
RUN set -ex \
        \
        && buildDeps=' \
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
        ' \
        && apt-get update \
        && apt-get install -y --no-install-recommends $buildDeps \
        && rm -rf /var/lib/apt/lists/*

RUN gem install bugspots

# nodejs
ENV REGISTRY_URL localhost
RUN mkdir /opt/node
RUN set -x && curl -fsSL https://nodejs.org/dist/v4.2.6/node-v4.2.6-linux-x64.tar.gz \
    | tar -xzC /opt/node && \
    chown -R root:root /opt/node/node-v4.2.6-linux-x64 && \
    chmod 775 /opt/node/node-v4.2.6-linux-x64 && \
    ln -s /opt/node/node-v4.2.6-linux-x64 /opt/node/default && \
    /opt/node/default/bin/npm config -g set registry  http://${REGISTRY_URL}/nexus/content/groups/npm/
# tslint
RUN /opt/node/default/bin/npm config set proxy null && \
    /opt/node/default/bin/npm config set https-proxy null && \
    /opt/node/default/bin/npm config set registry http://registry.npmjs.org/ && \
    /opt/node/default/bin/npm install tslint typescript -g

# jq
RUN set -x && curl -sLo /usr/local/bin/jq https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 && \
    chmod +x /usr/local/bin/jq

# sonar-scanner
RUN apt-get update && apt-get install -y unzip
RUN mkdir /opt/sonar-scanner
RUN set -x && curl -sLo /opt/sonar-scanner/sonar-scanner-2.6.zip https://sonarsource.bintray.com/Distribution/sonar-scanner-cli/sonar-scanner-2.6.zip && \
    unzip -d /opt/sonar-scanner  /opt/sonar-scanner/sonar-scanner-2.6.zip && \
    ln -s /opt/sonar-scanner/sonar-scanner-2.6/ /opt/sonar-scanner/default && \
    chown -R jenkins:jenkins /opt/sonar-scanner/sonar-scanner-2.6/ && \
    rm -f /opt/sonar-scanner/sonar-scanner-2.6.zip

ENV SONAR_RUNNER_HOME=/opt/sonar-scanner/default
ENV PATH $PATH:/opt/sonar-scanner/default/bin

COPY sonar-runner.properties ./sonar-scanner/conf/sonar-scanner.properties
#CMD sonar-scanner -Dsonar.projectBaseDir=./src

USER "${JENKINS_USER}"
