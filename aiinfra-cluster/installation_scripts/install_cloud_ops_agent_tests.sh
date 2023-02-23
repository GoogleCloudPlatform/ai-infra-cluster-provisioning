. <(grep -v '^main$' ./install_cloud_ops_agent.sh)

# helper functions

print_array () {
    for item in "${@}"; do
        echo "${item}"
    done
}

# gen_exponential tests

fails_on_n_eq_one_y_ne_one () { # test gen_exponential
    ! 2>/dev/null gen_exponential 1 2
}

gens_powers_of_two () { # test gen_exponential
    local expected=(1.0 2.0 4.0 8.0)
    diff \
        <(print_array "${expected[@]}") \
        <(gen_exponential 4 8)
}

# gen_backoff_times tests

gens_nothing_when_count_eq_zero () { # test gen_backoff_times
    [ -z "$(gen_backoff_times 0 8)" ]
}

gens_under_max_when_count_eq_one () { # test gen_backoff_times
    local t=8
    output="$(gen_backoff_times 1 ${t})"
    [ "${#output[@]}" -eq 1 ] \
        && [ $(echo "0 < ${output[0]}" | bc -l) -eq 1 ] \
        && [ $(echo "${output[0]} < ${t}" | bc -l) -eq 1 ]
}
