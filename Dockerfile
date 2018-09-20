FROM openfrontier/jenkins-swarm-maven-slave:oracle-jdk

MAINTAINER XJD <xing.jiudong@trans-cosmos.com.cn>

ENV NODEJS_VERSION=v4.2.6 \
    JQ_VERSION=1.5 \
    SONAR_SCANNER_VERSION=2.6

ENV REGISTRY_HOST=${REGISTRY_URL:-localhost}

USER root

RUN yum -y groupinstall 'Development Tools' && yum -y install \
    ImageMagick-devel \
    bzip2-devel \
    libcurl \
    libcurl-devel \
    openssl-devel \
    libevent-devel \
    libffi-devel \
    glib2-devel \
    libjpeg-devel \
    ncurses-devel \
    readline \
    readline-devel \
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

# To Build ruby 2.1, Autoconf version 2.67 or higher is required
RUN mkdir -p /usr/src/autoconf \
    && curl -fsSL http://ftp.gnu.org/gnu/autoconf/autoconf-2.69.tar.gz \
    | tar -xzC /usr/src/autoconf \
    && cd /usr/src/autoconf/autoconf-2.69 \
    && ./configure \
    && make \
    && make install \
    && rm -r /usr/src/autoconf    

ENV RUBY_MAJOR 2.3
ENV RUBY_VERSION 2.3.0

# some of ruby's build scripts are written in ruby
# we purge this later to make sure our final image uses what we just built
RUN yum -y install ruby && yum clean all \
	&& mkdir -p /usr/src/ruby \
	&& curl -SL "http://cache.ruby-lang.org/pub/ruby/$RUBY_MAJOR/ruby-$RUBY_VERSION.tar.bz2" \
		| tar -xjC /usr/src/ruby --strip-components=1 \
	&& cd /usr/src/ruby \
	&& autoconf \
	&& ./configure --disable-install-doc \
	&& make -j"$(nproc)" \
	&& make install

# skip installing gem documentation
RUN echo 'gem: --no-rdoc --no-ri' >> "$HOME/.gemrc"

# install things globally, for great justice
ENV GEM_HOME /usr/local/bundle
ENV PATH $GEM_HOME/bin:$PATH
RUN gem install bundler \
	&& bundle config --global path "$GEM_HOME" \
	&& bundle config --global bin "$GEM_HOME/bin"

# don't create ".bundle" in all our apps
ENV BUNDLE_APP_CONFIG $GEM_HOME

# Install bugspots
RUN gem install bugspots

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
