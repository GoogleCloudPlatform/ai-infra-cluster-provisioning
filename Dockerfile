FROM gcr.io/google.com/cloudsdktool/cloud-sdk as base
WORKDIR /root/aiinfra
RUN apt-get update \
    && apt-get --quiet install -y git bash curl jq zip \
    && apt-get --quiet clean autoclean \
    && apt-get --quiet autoremove --yes \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/ \
    && mkdir -p /root/.local/bin
ENV PATH="${PATH}:/usr/local/gcloud/google-cloud-sdk/bin:/root/.local/bin"
ENV TERRAFORM_VERSION="1.4.6"
RUN curl -s https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -o ./terraform.zip \
    && unzip -uq ./terraform.zip \
    && rm -f ./terraform.zip \
    && mv ./terraform /root/.local/bin/terraform

FROM base as test
COPY scripts ./scripts
COPY terraform ./terraform
COPY test ./test
ENTRYPOINT ["./test/run_tests.sh"]

FROM base as deploy
COPY scripts ./scripts
COPY terraform ./terraform
ENTRYPOINT ["./scripts/entrypoint.sh"]
