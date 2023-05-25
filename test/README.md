# Structure

## Test Runner

Each set of tests are run with a single script (`run.sh` in their respective
directories) which source two collections of functions -- the runner and the
tests. The test runner's `main` function will look for all functions that match
the prefix `test::` or any regex given as a command line argument.

## Continuous and PR

There are two `cloudbuild.yaml` files at the top-level directory of this
repository -- [pr](../cloudbuild-pr.yaml) and
[continuous](../cloudbuild-continuous.yaml) which correspond to the two sets of
tests found in this directory and are run via the two test targets in the
dockerfile.

### PR tests

PR tests run during every pull request into a protected branch -- `develop` and
`main`. These tests are unit tests for all bash code and as close to unit tests
as we can get for all terraform modules. The terraform tests have a few steps:
- `terraform init`: this is called in a dummy test before all the other tests
  of a module
- `terraform plan`: checks if the configuration is valid and generates a file
  with all the changes to the infrastructure
- `terraform show`: converts the terraform plan into json
- `jq contains`: checks if a json object is completely contained within another

The `jq` step is how we tell whether all the modules and resources actually get
created and whether they have the correct configurationo after any manipulation
of variables within the `locals` blocks.

### Continuous

Continuous tests run on every update to a protected branch -- so after a PR is
merged. These tests are more of end-to-end tests and use the [docker
entrypoint](../scripts/entrypoint.sh) to actually create and destroy
infrastructure. This only tests that infrastructure can be created -- nothing
to do with whether it is created correctly.

# How to run

## On host machine

In order to run the tests, you must be in the top-level directory of the
repository (this is because paths passed to the `source` command are relative
to the directory from which you are executing -- the top level was chosen in
order to eliminate having to follow a bunch of `../../../`s). Once there, run:
```bash
./test/pr/run.sh
./test/continuous/run.sh
```

## In a docker container

Each set of tests has a separate target in the dockerfile. For PR tests, run:
```bash
docker build --pull \
  --target test-pr \
  --tag test \
  .
docker run --rm \
  --volume "${HOME}/.config/gcloud:/root/.config/gcloud:rw" \
  test
```

And then for continuous tests, similarly run:
```bash
docker build --pull \
  --target test-continuous \
  --tag test \
  .
docker run --rm \
  --volume "${HOME}/.config/gcloud:/root/.config/gcloud:rw" \
  test
```
