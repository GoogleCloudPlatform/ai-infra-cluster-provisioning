FROM gcr.io/google.com/cloudsdktool/cloud-sdk as base

RUN apt-get update && apt-get install git bash bc curl jq python3 software-properties-common wget ca-certificates zip -y

##########################################################################################
# Install terraform
##########################################################################################
ENV TERRAFORM_VERSION="1.3.7"
ENV ROOT_MODULE_DIR="/usr/primary"
ENV CACHE_DIR="${ROOT_MODULE_DIR}/.terraform"
RUN wget -q https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && unzip terraform* \
    && mv terraform /usr/local/bin/terraform \
    && chmod +x /usr/local/bin/terraform \
    && rm terraform* \
    && mkdir -p "${CACHE_DIR}/plugin-cache" \
    && echo "plugin_cache_dir = \"${CACHE_DIR}/plugin-cache\"" >"${HOME}/.terraformrc"

##########################################################################################
# Clean up container, copy files in, and configure terraform
##########################################################################################
RUN apt-get --quiet clean autoclean && apt-get --quiet autoremove --yes && rm -rf /var/lib/{apt,dpkg,cache,log}/
ENV PATH $PATH:/usr/local/gcloud/google-cloud-sdk/bin
COPY aiinfra-cluster/ "${ROOT_MODULE_DIR}"
ARG TF_INIT=true
RUN if [ "${TF_INIT}" = true ]; then terraform -chdir=/usr/primary init; fi
COPY setup-scripts/ /usr/
COPY examples/ /usr/examples/


##########################################################################################
# Test target
##########################################################################################
FROM base as test
COPY test/ /test/
RUN chmod +x /test/run_tests.sh
ENTRYPOINT ["/test/run_tests.sh"]

##########################################################################################
# Deploy target
##########################################################################################
FROM base as deploy
RUN chmod +x /usr/entrypoint.sh
ENTRYPOINT ["/usr/entrypoint.sh"]
