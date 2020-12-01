FROM ghcr.io/linuxserver/baseimage-ubuntu:bionic

# set version label
ARG BUILD_DATE
ARG VERSION
ARG HEDGEDOC_RELEASE
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="chbmb"

# environment settings
ARG DEBIAN_FRONTEND="noninteractive"
ENV NODE_ENV production

RUN \
 echo "**** install build packages ****" && \
 apt-get update && \
 apt-get install -y \
	git \
	gnupg \
	jq \
	libssl-dev && \
 echo "**** install runtime *****" && \
 curl -s https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - && \
 echo 'deb https://deb.nodesource.com/node_12.x bionic main' > /etc/apt/sources.list.d/nodesource.list && \
 echo "**** install yarn repository ****" && \
 curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
 echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list && \
 apt-get update && \
 apt-get install -y \
	fontconfig \
	fonts-noto \
	netcat-openbsd \
	nodejs \
	yarn && \
 echo "**** install hedgedoc ****" && \
 if [ -z ${HEDGEDOC_RELEASE+x} ]; then \
	HEDGEDOC_RELEASE=$(curl -sX GET "https://api.github.com/repos/hedgedoc/hedgedoc/releases" \
	| jq -r '.[0] | .tag_name'); \
 fi && \
 curl -o \
	/tmp/hedgedoc.tar.gz -L \
	"https://github.com/hedgedoc/hedgedoc/archive/${HEDGEDOC_RELEASE}.tar.gz" && \
 mkdir -p \
	/opt/hedgedoc && \
 tar xf /tmp/hedgedoc.tar.gz -C \
	/opt/hedgedoc --strip-components=1 && \
 cd /opt/hedgedoc && \
 bin/setup && \
 npm run build && \
 echo "**** cleanup ****" && \
 yarn cache clean && \
 apt-get -y purge \
	git \
	gnupg \
	jq \
	libssl-dev && \
 apt-get -y autoremove && \
 rm -rf \
	/tmp/* \
	/var/lib/apt/lists/* \
	/var/tmp/*

# add local files
COPY root/ / 

# ports and volumes
EXPOSE 3000
VOLUME /config
