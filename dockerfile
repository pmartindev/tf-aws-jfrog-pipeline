 FROM ubuntu:18.04
 
 ENV DOTNET_SDK_VERSION="2.2.105"

 USER root

 # Install tools
 RUN apt-get update
 RUN apt-get install -y wget
 RUN apt-get install -y unzip
 RUN apt-get install -y curl

 # Install terraform
 RUN wget --quiet https://releases.hashicorp.com/terraform/0.11.3/terraform_0.11.3_linux_amd64.zip \
  && unzip terraform_0.11.3_linux_amd64.zip \
  && mv terraform /usr/bin \
  && rm terraform_0.11.3_linux_amd64.zip

 # Install jfrog cli
 RUN wget https://dl.bintray.com/jfrog/jfrog-cli-go/1.12.1/jfrog-cli-linux-amd64/jfrog \
 && chmod +x jfrog

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

# Trigger the population of the local package cache
RUN set -ex \
    && mkdir warmup \
    && cd warmup \
    && dotnet new \