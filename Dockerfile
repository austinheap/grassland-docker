FROM python:3.6.5-stretch
MAINTAINER austinheap <me@austinheap.com>
EXPOSE 3000/tcp 8080/tcp
VOLUME /root/.grassland
WORKDIR /opt

# metadata
ARG BUILD_DATE
ARG VCS_URL
ARG VCS_REF
ARG VERSION

LABEL \
 org.label-schema.build-date=$BUILD_DATE \
 org.label-schema.description="Dockerfiles and scripts for Grassland network, based on configuration settings." \
 org.label-schema.docker.cmd.debug="docker exec -it $CONTAINER shell" \
 org.label-schema.docker.cmd.help="docker exec -it $CONTAINER help" \
 org.label-schema.docker.cmd.test="docker exec -it $CONTAINER validate" \
 org.label-schema.name="Grassland for Docker" \
 org.label-schema.schema-version="1.0" \
 org.label-schema.url="https://austinheap.github.io/grassland-docker/" \
 org.label-schema.vcs-url=$VCS_URL \
 org.label-schema.vcs-ref=$VCS_REF \
 org.label-schema.vendor="Austin Heap" \
 org.label-schema.version=$VERSION \
 com.microscaling.docker.dockerfile="/Dockerfile" \
 com.microscaling.license="MIT"

ENV VERSION=$VERSION

# env
ARG BUILD_ENV_FILE=/opt/env.sh
ENV ENV_FILE=$BUILD_ENV_FILE

ARG BUILD_VIRTUAL_ENV=/opt/venv
ENV VIRTUAL_ENV=$BUILD_VIRTUAL_ENV

RUN \
 mkdir -p "$(dirname "${ENV_FILE}")" && \
 echo "# created by grassland-docker @ $(date)" > "${ENV_FILE}.orig" && \
 cp -v "${ENV_FILE}.orig" "${ENV_FILE}" && \
 pip3 install --upgrade pip && \
 pip3 install virtualenv && \
 python3 -m virtualenv --python=/usr/local/bin/python3 ${VIRTUAL_ENV}

ENV ENV=$ENV_FILE
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# deps
ARG DEBIAN_FRONTEND=noninteractive
ARG UBUNTU_APT_SITE=ubuntu.cs.utah.edu

ARG BUILD_PYTHON_VERSION=3.6.5
ENV PYTHON_VERSION=$BUILD_PYTHON_VERSION

ARG BUILD_OPENCV_VERSION=3.4.2
ENV OPENCV_VERSION=$BUILD_OPENCV_VERSION

ARG BUILD_AWS_VERSION=1.16
ENV AWS_VERSION=$BUILD_AWS_VERSION

ARG BUILD_NVM_VERSION=0.34.0
ENV NVM_VERSION=$BUILD_NVM_VERSION

ARG BUILD_NODE_VERSION=8.10.0
ENV NODE_VERSION=$BUILD_NODE_VERSION

ARG BUILD_SERVERLESS_VERSION=1.43.0
ENV SERVERLESS_VERSION=$BUILD_SERVERLESS_VERSION

ARG BUILD_NVM_DIR=/opt/nvm
ENV NVM_DIR=$BUILD_NVM_DIR

ENV HTTP_PROXY=http://squid-deb-proxy.local:8000/

ADD http://us.archive.ubuntu.com/ubuntu/pool/main/libj/libjpeg-turbo/libjpeg-turbo8_1.4.2-0ubuntu3_amd64.deb /tmp
ADD http://us.archive.ubuntu.com/ubuntu/pool/main/libj/libjpeg8-empty/libjpeg8_8c-2ubuntu8_amd64.deb /tmp
ADD http://security.ubuntu.com/ubuntu/pool/main/j/jasper/libjasper1_1.900.1-debian1-2.4ubuntu1.2_amd64.deb /tmp
ADD http://security.ubuntu.com/ubuntu/pool/main/j/jasper/libjasper-dev_1.900.1-debian1-2.4ubuntu1.2_amd64.deb /tmp

RUN \
 sed -E -i "s/([a-z]+.)?archive.ubuntu.com/$UBUNTU_APT_SITE/g" /etc/apt/sources.list && \
 sed -i "s/security.ubuntu.com/$UBUNTU_APT_SITE/g" /etc/apt/sources.list && \
 apt-get update && \
 apt-get upgrade -y -qq --no-install-recommends && \
 apt-get install -y -qq --no-install-recommends \
  build-essential cmake git wget curl unzip yasm pkg-config libswscale-dev libtbb2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev libavformat-dev \
  libpq-dev libv4l-dev libgtk2.0-dev libavcodec-dev libtbb2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev libdc1394-22-dev libglib2.0-0 \
  libsm6 libxrender1 locales libxext6 groff vim nano jq procps v4l-utils ca-certificates && \
 dpkg -i /tmp/*.deb && \
 pip3 install awscli numpy && \
 apt-get clean && \
 rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin /tmp/*.deb && \
 wget -q -O "/${OPENCV_VERSION}.zip" https://github.com/opencv/opencv/archive/${OPENCV_VERSION}.zip && \
 unzip -qq "/${OPENCV_VERSION}.zip" -d / && \
 mkdir "/opencv-${OPENCV_VERSION}/cmake_binary" && \
 cd "/opencv-${OPENCV_VERSION}/cmake_binary" && \
 cmake -DBUILD_TIFF=ON -DBUILD_opencv_java=OFF -DWITH_CUDA=OFF -DENABLE_AVX=ON -DWITH_OPENGL=ON -DWITH_OPENCL=ON -DWITH_IPP=ON -DWITH_TBB=ON -DWITH_EIGEN=ON \
       -DWITH_V4L=ON -DBUILD_TESTS=OFF -DBUILD_PERF_TESTS=OFF -DCMAKE_BUILD_TYPE=RELEASE -DCMAKE_INSTALL_PREFIX=$(python3 -c "import sys; print(sys.prefix)") \
       -DPYTHON_EXECUTABLE=$(which python3) -DPYTHON_INCLUDE_DIR=$(python3 -c "from distutils.sysconfig import get_python_inc; print(get_python_inc())") \
       -DPYTHON_PACKAGES_PATH=$(python3 -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())") .. && \
 make -j4 install && \
 cd /opt && \
 rm -rf "/${OPENCV_VERSION}.zip" "/opencv-${OPENCV_VERSION}" && \
 mkdir -p "${NVM_DIR}" && \
 curl -s -o- "https://raw.githubusercontent.com/creationix/nvm/v${NVM_VERSION}/install.sh" | bash && \
 . "${NVM_DIR}/nvm.sh" && \
 nvm install ${NODE_VERSION} && \
 nvm alias default ${NODE_VERSION} && \
 npm install -g try-thread-sleep && \
 npm install -g serverless --ignore-scripts spawn-sync

ENV NODE_PATH="$NVM_DIR/v$NODE_VERSION/lib/node_modules"
ENV PATH="$NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH"

# data
ARG BUILD_VENDORED_PATH=/opt/data/vendored.zip
ENV VENDORED_PATH=$BUILD_VENDORED_PATH

ARG BUILD_VENDORED_URL=https://downloads.grassland.network/packages/node_lite_object_detection/vendored.zip
ENV VENDORED_URL=$BUILD_VENDORED_URL

ARG BUILD_VENDORED_HASH=88c0fbf8aeb7de97cfc71b2201c97277
ENV VENDORED_HASH=$BUILD_VENDORED_HASH

ARG BUILD_EON_PATH=/opt/data/eon_0.pb
ENV EON_PATH=$BUILD_EON_PATH

ARG BUILD_EON_URL=https://downloads.grassland.network/models/eon_0.pb
ENV EON_URL=$BUILD_EON_URL

ARG BUILD_EON_HASH=1f1902262c16c2d9acb9bc4f8a8c266f
ENV EON_HASH=$BUILD_EON_HASH

RUN \
 mkdir -p "$(dirname "${VENDORED_PATH}")" && \
 curl -s -o "${VENDORED_PATH}" "${VENDORED_URL}" && \
 echo "${VENDORED_HASH}  ${VENDORED_PATH}" > "${VENDORED_PATH}.md5" && \
 md5sum -c "${VENDORED_PATH}.md5" && echo -n "Checksum passed: " && cat "${VENDORED_PATH}.md5" && rm "${VENDORED_PATH}.md5" && \
 mkdir -p "$(dirname "${EON_PATH}")" && \
 curl -s -o "${EON_PATH}" "${EON_URL}" && \
 echo "${EON_HASH}  ${EON_PATH}" > "${EON_PATH}.md5" && \
 md5sum -c "${EON_PATH}.md5" && echo -n "Checksum passed: " && cat "${EON_PATH}.md5" && rm "${EON_PATH}.md5"

# node_lite/node_lite_object_detection
ARG BUILD_RELEASE=acec8a859e111236beb3bfd10dd11909a0ae0f3c
ENV RELEASE=$BUILD_RELEASE

ARG BUILD_DETECTION_RELEASE=b03ca01211270efb1ceafaff8947415d12b75dda
ENV DETECTION_RELEASE=$BUILD_DETECTION_RELEASE

RUN \
 cd /opt && \
 git clone https://github.com/grasslandnetwork/node_lite && \
 cd node_lite && \
 git checkout -b docker-build ${RELEASE} && \
 pip3 install -r requirements.txt && \
 cd /opt/node_lite/gui && \
 npm install && \
 cd /opt && \
 git clone https://github.com/grasslandnetwork/node_lite_object_detection && \
 cd node_lite_object_detection && \
 git checkout -b docker-build ${DETECTION_RELEASE} && \
 rm -rf "/opt/node_lite_object_detection/vendored" && \
 unzip -qq "${VENDORED_PATH}" -d "/opt/node_lite_object_detection"

# config
ARG BUILD_AWS_ACCESS_KEY_ID=default_value
ENV AWS_ACCESS_KEY_ID=$BUILD_AWS_ACCESS_KEY_ID

ARG BUILD_AWS_SECRET_ACCESS_KEY=default_value
ENV AWS_SECRET_ACCESS_KEY=$BUILD_AWS_SECRET_ACCESS_KEY

ARG BUILD_AWS_DEFAULT_REGION=default_value
ENV AWS_DEFAULT_REGION=$BUILD_AWS_DEFAULT_REGION

ARG BUILD_GRASSLAND_FRAME_S3_BUCKET=default_value
ENV GRASSLAND_FRAME_S3_BUCKET=$BUILD_GRASSLAND_FRAME_S3_BUCKET

ARG BUILD_GRASSLAND_MODEL_S3_BUCKET=default_value
ENV GRASSLAND_MODEL_S3_BUCKET=$BUILD_GRASSLAND_MODEL_S3_BUCKET

ARG BUILD_LAMBDA_DETECTION_URL=default_value
ENV LAMBDA_DETECTION_URL=$BUILD_LAMBDA_DETECTION_URL

ARG BUILD_MAPBOX_ACCESS_TOKEN=default_value
ENV MapboxAccessToken=$BUILD_MAPBOX_ACCESS_TOKEN

ARG BUILD_DISPLAY=host.docker.internal:0
ENV DISPLAY=$BUILD_DISPLAY

# scripts
COPY docker-config.sh /docker-config.sh
COPY docker-functions.sh /docker-functions.sh
COPY docker-commands.sh /docker-commands.sh
COPY docker-entrypoint.sh /docker-entrypoint.sh

RUN \
 md5sum /docker-config.sh > .docker-config.sh.md5 && \
 md5sum /docker-functions.sh > .docker-functions.sh.md5 && \
 md5sum /docker-commands.sh > .docker-commands.sh.md5 && \
 md5sum /docker-entrypoint.sh > .docker-entrypoint.sh.md5 && \
 CONTAINER_QUIET=true /docker-entrypoint.sh validate:versions && \
 ln -s /docker-entrypoint.sh /usr/local/bin/grassland

# defaults
ENTRYPOINT ["/usr/local/bin/grassland"]
CMD ["default"]
