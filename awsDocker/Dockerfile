# Copyright 2017-2017 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Amazon Software License (the "License"). You may not use this file except in compliance with the License.
# A copy of the License is located at
#
#    http://aws.amazon.com/asl/
#
# or in the "license" file accompanying this file.
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
# See the License for the specific language governing permissions and limitations under the License.

FROM ubuntu:18.04

ENV  PYTHON_VERSION="3.7.3" \
 DOTNET_SDK_VERSION="2.2.105" \
 DOCKER_VERSION="18.09.3" \
 DOCKER_COMPOSE_VERSION="1.23.2"


#****************        Utilities     ********************************************* 
ENV DOCKER_BUCKET="download.docker.com" \    
    DOCKER_CHANNEL="stable" \
    DOCKER_SHA256="8b886106cfc362f1043debfe178c35b6f73ec42380b034a3919a235fe331e053" \
    DIND_COMMIT="3b5fac462d21ca164b3778647420016315289034" \    
    GITVERSION_VERSION="4.0.0" \
    DEBIAN_FRONTEND="noninteractive" \
    SRC_DIR="/usr/src"

# Install git, SSH, and other utilities
RUN set -ex \
    && echo 'Acquire::CompressionTypes::Order:: "gz";' > /etc/apt/apt.conf.d/99use-gzip-compression \
    && apt-get update \
    && apt install -y apt-transport-https \
    && apt-get update \
    && apt-get install software-properties-common -y --no-install-recommends \
    && apt-add-repository ppa:git-core/ppa \
    && apt-get update \
    && apt-get install git=1:2.* -y --no-install-recommends \
    && git version \
    && apt-get install -y --no-install-recommends openssh-client \
    && mkdir ~/.ssh \
    && touch ~/.ssh/known_hosts \
    && ssh-keyscan -t rsa,dsa -H github.com >> ~/.ssh/known_hosts \
    && ssh-keyscan -t rsa,dsa -H bitbucket.org >> ~/.ssh/known_hosts \
    && chmod 600 ~/.ssh/known_hosts \
    && apt-get install -y --no-install-recommends \
       wget python3 python3-dev python3-pip python3-setuptools fakeroot ca-certificates jq \
       netbase gnupg dirmngr bzr mercurial procps \
       tar gzip zip autoconf automake \
       bzip2 file g++ gcc imagemagick \
       libbz2-dev libc6-dev libcurl4-openssl-dev libdb-dev \
       libevent-dev libffi-dev libgeoip-dev libglib2.0-dev \
       libjpeg-dev libkrb5-dev liblzma-dev \
       libmagickcore-dev libmagickwand-dev libmysqlclient-dev \
       libncurses5-dev libpq-dev libreadline-dev \
       libsqlite3-dev libssl-dev libtool libwebp-dev \
       libxml2-dev libxslt1-dev libyaml-dev make \
       patch xz-utils zlib1g-dev unzip curl \
       e2fsprogs iptables xfsprogs \
       mono-devel less groff liberror-perl \
       asciidoc build-essential bzr cvs cvsps docbook-xml docbook-xsl dpkg-dev \
       libdbd-sqlite3-perl libdbi-perl libdpkg-perl libhttp-date-perl \
       libio-pty-perl libserf-1-1 libsvn-perl libsvn1 libtcl8.6 libtimedate-perl \
       libxml2-utils libyaml-perl python-bzrlib python-configobj \
       sgml-base sgml-data subversion tcl tcl8.6 xml-core xmlto xsltproc \
       tk gettext gettext-base libapr1 libaprutil1 xvfb expect parallel \
    && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF \
    && echo "deb https://download.mono-project.com/repo/ubuntu stable-bionic main" | tee /etc/apt/sources.list.d/mono-official-stable.list \    
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Download and set up GitVersion
RUN set -ex \
    && wget "https://github.com/GitTools/GitVersion/releases/download/v${GITVERSION_VERSION}/GitVersion-bin-net40-v${GITVERSION_VERSION}.zip" -O /tmp/GitVersion_${GITVERSION_VERSION}.zip \
    && mkdir -p /usr/local/GitVersion_${GITVERSION_VERSION} \
    && unzip /tmp/GitVersion_${GITVERSION_VERSION}.zip -d /usr/local/GitVersion_${GITVERSION_VERSION} \
    && rm /tmp/GitVersion_${GITVERSION_VERSION}.zip \
    && echo "mono /usr/local/GitVersion_${GITVERSION_VERSION}/GitVersion.exe \$@" >> /usr/local/bin/gitversion \
    && chmod +x /usr/local/bin/gitversion
# Install Docker
RUN set -ex \
    && curl -fSL "https://${DOCKER_BUCKET}/linux/static/${DOCKER_CHANNEL}/x86_64/docker-${DOCKER_VERSION}.tgz" -o docker.tgz \
    && echo "${DOCKER_SHA256} *docker.tgz" | sha256sum -c - \
    && tar --extract --file docker.tgz --strip-components 1  --directory /usr/local/bin/ \
    && rm docker.tgz \
    && docker -v \
# set up subuid/subgid so that "--userns-remap=default" works out-of-the-box
    && addgroup dockremap \
    && useradd -g dockremap dockremap \
    && echo 'dockremap:165536:65536' >> /etc/subuid \
    && echo 'dockremap:165536:65536' >> /etc/subgid \
    && wget "https://raw.githubusercontent.com/docker/docker/${DIND_COMMIT}/hack/dind" -O /usr/local/bin/dind \
    && curl -L https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-Linux-x86_64 > /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/dind /usr/local/bin/docker-compose \
# Ensure docker-compose works
    && docker-compose version

# https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ECS_CLI_installation.html
RUN curl -sS -o /usr/local/bin/aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.11.5/2018-12-06/bin/linux/amd64/aws-iam-authenticator \
 && curl -sS -o /usr/local/bin/kubectl https://amazon-eks.s3-us-west-2.amazonaws.com/1.11.5/2018-12-06/bin/linux/amd64/kubectl \
 && curl -sS -o /usr/local/bin/ecs-cli https://s3.amazonaws.com/amazon-ecs-cli/ecs-cli-linux-amd64-latest \
 && chmod +x /usr/local/bin/kubectl /usr/local/bin/aws-iam-authenticator /usr/local/bin/ecs-cli

RUN set -ex \
    && pip3 install awscli boto3  

VOLUME /var/lib/docker

# Configure SSH
COPY ssh_config /root/.ssh/config

COPY runtimes.yml /codebuild/image/config/runtimes.yml

COPY dockerd-entrypoint.sh /usr/local/bin/

# #****************        PYTHON     ********************************************* 
# ENV PATH="/usr/local/bin:$PATH" \
#     GPG_KEY="0D96DF4D4110E5C43FBFB17F2D347EA6AA65421D" \
#     PYTHON_PIP_VERSION="19.0.3" \
#     LC_ALL=C.UTF-8 \
#     LANG=C.UTF-8

# RUN apt-get update && apt-get install -y --no-install-recommends \
#         tcl-dev tk-dev \
#     && rm -rf /var/lib/apt/lists/* \
#     \
#     && wget -O python.tar.xz "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz" \
#     && wget -O python.tar.xz.asc "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz.asc" \
#     && export GNUPGHOME="$(mktemp -d)" \
#     && (gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$GPG_KEY" \
#         || gpg --keyserver pgp.mit.edu --recv-keys "$GPG_KEY" \
#         || gpg --keyserver keyserver.ubuntu.com --recv-keys "$GPG_KEY") \
#     && gpg --batch --verify python.tar.xz.asc python.tar.xz \
#     && rm -r "$GNUPGHOME" python.tar.xz.asc \
#     && mkdir -p /usr/src/python \
#     && tar -xJC /usr/src/python --strip-components=1 -f python.tar.xz \
#     && rm python.tar.xz \
#     \
#     && cd /usr/src/python \
#     && ./configure \
#         --enable-loadable-sqlite-extensions \
#         --enable-shared \
#     && make -j$(nproc) \
#     && make install \
#     && ldconfig \
#     \
# # explicit path to "pip3" to ensure distribution-provided "pip3" cannot interfere
#     && if [ ! -e /usr/local/bin/pip3 ]; then : \
#         && wget -O /tmp/get-pip.py 'https://bootstrap.pypa.io/get-pip.py' \
#         && python3 /tmp/get-pip.py "pip==$PYTHON_PIP_VERSION" \
#         && rm /tmp/get-pip.py \
#     ; fi \
# # we use "--force-reinstall" for the case where the version of pip we're trying to install is the same as the version bundled with Python
# # ("Requirement already up-to-date: pip==8.1.2 in /usr/local/lib/python3.6/site-packages")
# # https://github.com/docker-library/python/pull/143#issuecomment-241032683
#     && pip3 install --no-cache-dir --upgrade --force-reinstall "pip==$PYTHON_PIP_VERSION" \
#         && pip install pipenv virtualenv --no-cache-dir \
# # then we use "pip list" to ensure we don't have more than one pip version installed
# # https://github.com/docker-library/python/pull/100
#     && [ "$(pip list |tac|tac| awk -F '[ ()]+' '$1 == "pip" { print $2; exit }')" = "$PYTHON_PIP_VERSION" ] \
#     \
#     && find /usr/local -depth \
#         \( \
#             \( -type d -a -name test -o -name tests \) \
#             -o \
#             \( -type f -a -name '*.pyc' -o -name '*.pyo' \) \
#         \) -exec rm -rf '{}' + \
#     && apt-get purge -y --auto-remove tcl-dev tk-dev \
#     && rm -rf /usr/src/python ~/.cache \
#     && cd /usr/local/bin \
#     && { [ -e easy_install ] || ln -s easy_install-* easy_install; } \
#     && ln -s idle3 idle \
#     && ln -s pydoc3 pydoc \
#     && ln -s python3 python \
#     && ln -s python3-config python-config \
#         && rm -fr /var/lib/apt/lists/* /tmp/* /var/tmp/*

# #****************      END PYTHON     ********************************************* 

#****************     .NET-CORE     *******************************************************
RUN set -ex \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        libc6 \
        libgcc1 \
        libgssapi-krb5-2 \
        liblttng-ust0 \
        libstdc++6 \
        zlib1g \
        software-properties-common \
    && add-apt-repository ppa:ubuntu-toolchain-r/test -y \
    && apt-get update \   
    && rm -rf /var/lib/apt/lists/*

# Install .NET Core SDK
ENV DOTNET_SDK_DOWNLOAD_URL https://dotnetcli.blob.core.windows.net/dotnet/Sdk/$DOTNET_SDK_VERSION/dotnet-sdk-$DOTNET_SDK_VERSION-linux-x64.tar.gz
ENV DOTNET_SDK_DOWNLOAD_SHA B7AD26B344995DE91848ADEC56BDA5DFE5FEF0B83ABAA3E4376DC790CF9786E945B625DE1AE4CECAF5C5BEF86284652886ED87696581553AEDA89EE2E2E99517

RUN set -ex \
    && curl -SL $DOTNET_SDK_DOWNLOAD_URL --output dotnet.tar.gz \
    && echo "$DOTNET_SDK_DOWNLOAD_SHA dotnet.tar.gz" | sha512sum -c - \
    && mkdir -p /usr/share/dotnet \
    && tar -zxf dotnet.tar.gz -C /usr/share/dotnet \
    && rm dotnet.tar.gz \
    && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet

# Add .NET Core Global Tools install folder to PATH
ENV PATH "~/.dotnet/tools/:$PATH"

# Trigger the population of the local package cache
ENV NUGET_XMLDOC_MODE skip
RUN set -ex \
    && mkdir warmup \
    && cd warmup \
    && dotnet new \
    && cd .. \
    && rm -rf warmup \
    && rm -rf /tmp/NuGetScratch

# Install Powershell Core
# See instructions at https://docs.microsoft.com/en-us/powershell/scripting/setup/installing-powershell-core-on-linux
ENV POWERSHELL_VERSION 6.1.3
ENV POWERSHELL_DOWNLOAD_URL https://github.com/PowerShell/PowerShell/releases/download/v$POWERSHELL_VERSION/powershell-$POWERSHELL_VERSION-linux-x64.tar.gz
ENV POWERSHELL_DOWNLOAD_SHA E728B51487288FB395C2BA41CE978DE265049C5BD995AFF0B06F1573DB831C8B

RUN set -ex \
    && curl -SL $POWERSHELL_DOWNLOAD_URL --output powershell.tar.gz \
    && echo "$POWERSHELL_DOWNLOAD_SHA powershell.tar.gz" | sha256sum -c - \
    && mkdir -p /opt/microsoft/powershell/$POWERSHELL_VERSION \
    && tar zxf powershell.tar.gz -C /opt/microsoft/powershell/$POWERSHELL_VERSION \
    && rm powershell.tar.gz \
    && ln -s /opt/microsoft/powershell/$POWERSHELL_VERSION/pwsh /usr/bin/pwsh
#****************     END .NET-CORE     *******************************************************

#****************     TERRAFORM     *******************************************************
 
 RUN wget --quiet https://releases.hashicorp.com/terraform/0.11.13/terraform_0.11.13_linux_amd64.zip \
  && unzip terraform_0.11.13_linux_amd64.zip \
  && mv terraform /usr/bin \
  && rm terraform_0.11.13_linux_amd64.zip

#****************     END TERRAFORM     *******************************************************

#****************     JFROG     *******************************************************
 
 RUN wget https://dl.bintray.com/jfrog/jfrog-cli-go/1.12.1/jfrog-cli-linux-amd64/jfrog \
 && chmod +x jfrog

#****************     END JFROG     *******************************************************
