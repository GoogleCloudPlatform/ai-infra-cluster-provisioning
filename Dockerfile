FROM debian:stable-slim

RUN apt-get update && apt-get install git bash curl python3 software-properties-common wget ca-certificates zip -y

##########################################################################################
# Install gcloud
##########################################################################################
RUN curl https://dl.google.com/dl/cloudsdk/release/google-cloud-sdk.tar.gz > /tmp/google-cloud-sdk.tar.gz

# Install the package
RUN mkdir -p /usr/local/gcloud \
  && tar -C /usr/local/gcloud -xvf /tmp/google-cloud-sdk.tar.gz \
  && /usr/local/gcloud/google-cloud-sdk/install.sh

##########################################################################################
# Install terraform
##########################################################################################

ENV TERRAFORM_VERSION="1.3.0"

RUN wget -q https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && unzip terraform* && mv terraform /usr/local/bin/terraform \
    && chmod +x /usr/local/bin/terraform && rm terraform* 

##########################################################################################
# Clean Up Container
##########################################################################################
RUN apt-get clean autoclean && apt-get autoremove --yes && rm -rf /var/lib/{apt,dpkg,cache,log}/

ENV PATH $PATH:/usr/local/gcloud/google-cloud-sdk/bin
COPY tfconfig/ /usr/primary/
COPY scripts/ /usr/
COPY examples/ /usr/examples/
RUN chmod +x /usr/entrypoint.sh
ENTRYPOINT ["/usr/entrypoint.sh"]