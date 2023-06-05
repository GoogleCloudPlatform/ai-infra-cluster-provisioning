. ./test/helpers.sh

SOURCING=true
. ./scripts/enable_ops_agent.sh
unset SOURCING

# gen_exponential

test::enable_ops_agent::gen_exponential::fails_on_n_eq_one_y_ne_one () {
    EXPECT_FAIL enable_ops_agent::gen_exponential 1 2
}

test::enable_ops_agent::gen_exponential::gens_powers_of_two () {
    declare -ar expected=(1.0 2.0 4.0 8.0)
    declare -ar output=($(enable_ops_agent::gen_exponential 4 8))
    EXPECT_ARREQ expected output
}

# gen_backoff_times

test::enable_ops_agent::gen_backoff_times::gens_nothing_when_count_eq_zero () {
    EXPECT_STR_EMPTY "$(enable_ops_agent::gen_backoff_times 0 8)"
}

test::enable_ops_agent::gen_backoff_times::gens_under_max_when_count_eq_one () {
    local -r t=8
    declare -ar output=($(enable_ops_agent::gen_backoff_times 1 ${t}))
    EXPECT_EQ "${#output[@]}" 1
    EXPECT_EQ "$(echo "0 <= ${output[0]}" | bc -l)" 1
    EXPECT_EQ "$(echo "${output[0]} <= ${t}" | bc -l)" 1
}

test::enable_ops_agent::gen_backoff_times::gens_under_exponential_when_count_gt_one () {
    local -r n=4
    local -r t=8
    declare -ar output=($(enable_ops_agent::gen_backoff_times ${n} ${t}))
    declare -ar maximums=($(enable_ops_agent::gen_exponential ${n} ${t}))
    EXPECT_EQ "${#output[@]}" "${n}"
    for i in $(seq 0 "$((n - 1))"); do
        EXPECT_EQ "$(echo "0 <= ${output[$i]}" | bc -l)" 1
        EXPECT_EQ "$(echo "${output[$i]} <= ${t}" | bc -l)" 1
    done
}

# retry_with_backoff

enable_ops_agent::test::decrement_to_zero () {
    local -r var_name="${1}"
    [ "$((--${var_name}))" -le 0 ]
}

test::enable_ops_agent::retry_with_backoff::passes_when_one_attempt_given_and_one_needed () {
    local counter=1
    EXPECT_SUCCEED enable_ops_agent::retry_with_backoff \
        1 1 enable_ops_agent::test::decrement_to_zero counter
}

test::enable_ops_agent::retry_with_backoff::fails_when_one_attempt_given_and_two_needed () {
    local counter=2
    EXPECT_FAIL enable_ops_agent::retry_with_backoff \
        1 1 enable_ops_agent::test::decrement_to_zero counter
    EXPECT_EQ "${counter}" 1
}

test::enable_ops_agent::retry_with_backoff::passes_when_less_attempts_needed_than_given () {
    local counter=3
    EXPECT_SUCCEED enable_ops_agent::retry_with_backoff \
        4 1 enable_ops_agent::test::decrement_to_zero counter
}

test::enable_ops_agent::retry_with_backoff::fails_when_more_attempts_needed_than_given () {
    local counter=3
    EXPECT_FAIL enable_ops_agent::retry_with_backoff \
        2 1 enable_ops_agent::test::decrement_to_zero counter
    EXPECT_EQ "${counter}" 1
}
