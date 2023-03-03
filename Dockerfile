FROM gcr.io/google.com/cloudsdktool/cloud-sdk as base

RUN apt-get update && apt-get install git bash curl python3 software-properties-common wget ca-certificates zip -y

##########################################################################################
# Install terraform
##########################################################################################

ENV TERRAFORM_VERSION="1.3.7"

RUN wget -q https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && unzip terraform* && mv terraform /usr/local/bin/terraform \
    && chmod +x /usr/local/bin/terraform && rm terraform* 

##########################################################################################
# Clean Up Container
##########################################################################################
RUN apt-get clean autoclean && apt-get autoremove --yes && rm -rf /var/lib/{apt,dpkg,cache,log}/

FROM base as test
WORKDIR /test
RUN apt-get update \
    && apt-get install -y bc \
    && apt-get clean autoclean \
    && apt-get autoremove --yes \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/
COPY aiinfra-cluster/installation_scripts/ /test
RUN chmod +x /test/run_tests.sh
ENTRYPOINT ["./run_tests.sh"]

FROM base as deploy
ENV PATH $PATH:/usr/local/gcloud/google-cloud-sdk/bin
COPY aiinfra-cluster/ /usr/primary/
COPY scripts/ /usr/
COPY examples/ /usr/examples/
RUN chmod +x /usr/entrypoint.sh
ENTRYPOINT ["/usr/entrypoint.sh"]
