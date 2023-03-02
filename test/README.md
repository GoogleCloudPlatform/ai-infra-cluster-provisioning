# How to run

To run all tests, run `bash ./test/run_tests.sh`. Note that you must be in the
top-level directory of the repository in order to run this script. This is
because paths passed to the `source` command are relative to the directory from
which you are executing. The top level was chosen in order to eliminate having
to follow a bunch of `../../../`s.

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
