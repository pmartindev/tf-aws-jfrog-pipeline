 FROM ubuntu:18.04

 USER root

 # Install wget
 RUN apt-get update
 RUN apt-get install -y wget
 RUN apt-get install -y unzip
 # Install terraform
 RUN wget --quiet https://releases.hashicorp.com/terraform/0.11.3/terraform_0.11.3_linux_amd64.zip \
  && unzip terraform_0.11.3_linux_amd64.zip \
  && mv terraform /usr/bin \
  && rm terraform_0.11.3_linux_amd64.zip

 # Install jfrog cli
 RUN wget https://dl.bintray.com/jfrog/jfrog-cli-go/1.12.1/jfrog-cli-linux-amd64/jfrog
 RUN chmod +x jfrog
 RUN pwd
