. <(grep -v '^main$' ./install_cloud_ops_agent.sh)

# gen_exponential

fails_on_n_eq_one_y_ne_one () { # test gen_exponential
    EXPECT_FAIL gen_exponential 1 2
}

gens_powers_of_two () { # test gen_exponential
    local expected output
    declare -a expected=(1.0 2.0 4.0 8.0)
    declare -a output=($(gen_exponential 4 8))
    EXPECT_ARR_EQ expected output
}

# gen_backoff_times

gens_nothing_when_count_eq_zero () { # test gen_backoff_times
    [ -z "$(gen_backoff_times 0 8)" ]
}

gens_under_max_when_count_eq_one () { # test gen_backoff_times
    local t=8 output
    declare -a output=($(gen_backoff_times 1 ${t}))
    EXPECT [ "${#output[@]}" -eq 1 ]
    EXPECT [ $(echo "0 < ${output[0]}" | bc -l) -eq 1 ]
    EXPECT [ $(echo "${output[0]} < ${t}" | bc -l) -eq 1 ]
}

gens_under_exponential_when_count_gt_one () { # test gen_backoff_times
    local n=4 t=8 output maximums
    declare -a output=($(gen_backoff_times ${n} ${t}))
    declare -a maximums=($(gen_exponential ${n} ${t}))
    EXPECT [ "${#output[@]}" -eq ${n} ]
    for i in $(seq 0 "$((n - 1))"); do
        EXPECT [ $(echo "0 <= ${output[$i]}" | bc -l) -eq 1 ]
        EXPECT [ $(echo "${output[$i]} < ${t}" | bc -l) -eq 1 ]
    done
}

# retry_with_backoff

decrement_counter_to_zero () {
    [ "$((--counter))" -le 0 ]
}

passes_when_one_attempt_given_and_one_needed () { # test retry_with_backoff
    local counter=1
    EXPECT >/dev/null retry_with_backoff 1 1 decrement_counter_to_zero
}

fails_when_one_attempt_given_and_two_needed () { # test retry_with_backoff
    local counter=2
    EXPECT_FAIL >/dev/null retry_with_backoff 1 1 decrement_counter_to_zero
    EXPECT [ "${counter}" -eq 1 ]
}

passes_when_less_attempts_needed_than_given () { # test retry_with_backoff
    local counter=3
    EXPECT >/dev/null retry_with_backoff 4 1 decrement_counter_to_zero
}

fails_when_more_attempts_needed_than_given () { # test retry_with_backoff
    local counter=3
    EXPECT_FAIL >/dev/null retry_with_backoff 2 1 decrement_counter_to_zero
    EXPECT [ "${counter}" -eq 1 ]
}
