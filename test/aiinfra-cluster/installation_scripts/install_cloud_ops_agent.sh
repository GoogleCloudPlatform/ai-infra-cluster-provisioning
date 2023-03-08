. ./test/helpers.sh

SOURCING=true
. ./usr/primary/installation_scripts/install_cloud_ops_agent.sh
unset SOURCING

# gen_exponential

test::gen_exponential::fails_on_n_eq_one_y_ne_one () {
    EXPECT_FAIL gen_exponential 1 2
}

test::gen_exponential::gens_powers_of_two () {
    declare -ar expected=(1.0 2.0 4.0 8.0)
    declare -ar output=($(gen_exponential 4 8))
    EXPECT_ARREQ expected output
}

# gen_backoff_times

test::gen_backoff_times::gens_nothing_when_count_eq_zero () {
    EXPECT_STR_EMPTY "$(gen_backoff_times 0 8)"
}

test::gen_backoff_times::gens_under_max_when_count_eq_one () {
    local -r t=8
    declare -ar output=($(gen_backoff_times 1 ${t}))
    EXPECT_EQ "${#output[@]}" 1
    EXPECT_EQ "$(echo "0 <= ${output[0]}" | bc -l)" 1
    EXPECT_EQ "$(echo "${output[0]} <= ${t}" | bc -l)" 1
}

test::gen_backoff_times::gens_under_exponential_when_count_gt_one () {
    local -r n=4
    local -r t=8
    declare -ar output=($(gen_backoff_times ${n} ${t}))
    declare -ar maximums=($(gen_exponential ${n} ${t}))
    EXPECT_EQ "${#output[@]}" "${n}"
    for i in $(seq 0 "$((n - 1))"); do
        EXPECT_EQ "$(echo "0 <= ${output[$i]}" | bc -l)" 1
        EXPECT_EQ "$(echo "${output[$i]} <= ${t}" | bc -l)" 1
    done
}

# retry_with_backoff

decrement_to_zero () {
    local -r var_name="${1}"
    [ "$((--${var_name}))" -le 0 ]
}

test::retry_with_backoff::passes_when_one_attempt_given_and_one_needed () {
    local counter=1
    EXPECT_SUCCEED retry_with_backoff 1 1 decrement_to_zero counter
}

test::retry_with_backoff::fails_when_one_attempt_given_and_two_needed () {
    local counter=2
    EXPECT_FAIL retry_with_backoff 1 1 decrement_to_zero counter
    EXPECT_EQ "${counter}" 1
}

test::retry_with_backoff::passes_when_less_attempts_needed_than_given () {
    local counter=3
    EXPECT_SUCCEED retry_with_backoff 4 1 decrement_to_zero counter
}

test::retry_with_backoff::fails_when_more_attempts_needed_than_given () {
    local counter=3
    EXPECT_FAIL retry_with_backoff 2 1 decrement_to_zero counter
    EXPECT_EQ "${counter}" 1
}
