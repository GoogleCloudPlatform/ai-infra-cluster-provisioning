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
COPY terraform ./terraform

FROM base as test
COPY scripts ./scripts
COPY test ./test
ENTRYPOINT ["./test/run_tests.sh"]

FROM base as deploy
RUN for cluster in gke mig slurm; do \
    terraform -chdir="./terraform/modules/cluster/${cluster}" init; done
COPY scripts ./scripts
ENTRYPOINT ["./scripts/entrypoint.sh"]
