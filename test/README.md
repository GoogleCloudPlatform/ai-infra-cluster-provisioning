# How to run

In order to run the tests, you must be in the top-level directory of the
repository. This is because paths passed to the `source` command are relative to
the directory from which you are executing. The top level was chosen in order to
eliminate having to follow a bunch of `../../../`s.

The only way for that to happen right now is to run the docker container.
Support for host-machine running will come later. For now, this is the docker
command:
```bash
tag='prov-test' # or whatever
docker build --pull --target test --tag "${tag}" .
docker run -it -v "${HOME}/.config/gcloud:/root/.config/gcloud:rw" "${tag}"
```

One unfortunate aspect of building inside a docker container is that it will have to download modules and plugins each time you change any terraform code. This can be circumvented by disabling docker-build-time `terraform init` and providing the docker run command with a host-machine directory in which the downloads may persist between runs.
```bash
mkdir ./.terraform
tag='prov-test' # or whatever
docker build --pull \
  --build-arg TF_INIT=false \
  --target test \
  --tag "${tag}" \
  .
docker run -it \
  -v "${HOME}/.config/gcloud:/root/.config/gcloud:rw" \
  -v "${PWD}/.terraform:/usr/primary/.terraform:rw" \
  ${tag}"
```

# Structure

## Test naming convention

`test::group::case`:
- `test`: the literal string `test`.
- `group`: group into which tests will be organized to run -- typically the
  name of the function or script.
- `case`: the individual test case name/description.

## helpers.sh

File that should be `source`d -- not ran -- which contains functions common to
many test files.

## test files

The directory structure or `/test/` will be similar to the directory structure
of `/`. The location of test files within `/test/` should match the location
within `/` of the functions the files are testing.

Most if not all of these files will `source ./test/helpers.sh`.

## run_tests.sh

Usage:
```
./test/run_tests.sh [FILTER]

Parameters:
- FILTER (default: 'test::'): regex to filter which tests run
```

This script `source`s all the test files.
