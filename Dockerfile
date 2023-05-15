FROM gcr.io/google.com/cloudsdktool/cloud-sdk as base
RUN apt-get update \
    && apt-get --quiet install -y git bash curl jq zip \
    && apt-get --quiet clean autoclean \
    && apt-get --quiet autoremove --yes \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/
    #&& apt-get --quiet install -y git bash bc curl jq python3 software-properties-common wget ca-certificates zip \
ENV TERRAFORM_VERSION="1.4.6"
ENV PATH="${PATH}:/usr/local/gcloud/google-cloud-sdk/bin"
WORKDIR /root/aiinfra
RUN curl -s "https://releases.hashicorp.com/terraform/index.json" \
    | jq -rc '[ .versions[] | select(.version | test("^[0-9]{1,}\\.[0-9]{1,}\\.[0-9]{1,}$")) ] | last | .builds[] | select((.arch == "amd64") and (.os == "linux")) | [.url, .filename, .name] | join(" ")' \
    | while read url zip_archive executable; do \
        curl -s "${url}" -o "${zip_archive}" \
        && unzip -uq "${zip_archive}" \
        && rm -f "${zip_archive}" \
        && mv "${executable}" "/usr/local/bin/${executable}"; done

FROM base as test
COPY scripts ./scripts
COPY terraform ./terraform
COPY test ./test
ENTRYPOINT ["./test/run_tests.sh"]

FROM base as deploy
COPY scripts ./scripts
COPY terraform ./terraform
ENTRYPOINT ["./scripts/entrypoint.sh"]
