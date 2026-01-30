#!/bin/bash
# ============================================================================
# Linux Benchmark Suite - CPU Benchmarks
# ============================================================================
# CPU performance testing using sysbench
# ============================================================================

# ============================================================================
# CPU Benchmark Configuration
# ============================================================================

CPU_PRIME_LIMIT=20000
CPU_THREADS=$(nproc)
CPU_TIME=30

# ============================================================================
# Run CPU Benchmark
# ============================================================================

run_cpu_test() {
    log_header "CPU Performance Benchmark"
    
    local output_dir="${RESULT_DIR:-output}"
    local json_file="$output_dir/cpu.json"
    
    # Ensure output directory exists
    mkdir -p "$output_dir"
    
    echo -e "  ${BOLD}Test:${RESET}        Prime number calculation"
    echo -e "  ${BOLD}Prime limit:${RESET} $CPU_PRIME_LIMIT"
    echo -e "  ${BOLD}Duration:${RESET}    ${CPU_TIME}s per test"
    echo ""
    
    # Initialize JSON
    echo "{" > "$json_file"
    echo "  \"test_type\": \"cpu\"," >> "$json_file"
    echo "  \"timestamp\": \"$(date -Iseconds)\"," >> "$json_file"
    echo "  \"config\": {" >> "$json_file"
    echo "    \"prime_limit\": $CPU_PRIME_LIMIT," >> "$json_file"
    echo "    \"time_seconds\": $CPU_TIME" >> "$json_file"
    echo "  }," >> "$json_file"
    echo "  \"results\": {" >> "$json_file"
    
    # ─────────────────────────────────────────────────────────────────────────
    # Single-threaded test
    # ─────────────────────────────────────────────────────────────────────────
    
    log_section "Single-Threaded Performance"
    log "Running single-thread CPU test..." STEP
    
    local single_output=$(sysbench cpu \
        --cpu-max-prime=$CPU_PRIME_LIMIT \
        --threads=1 \
        --time=$CPU_TIME \
        run 2>&1)
    
    local single_events=$(echo "$single_output" | grep "total number of events" | awk '{print $NF}')
    local single_eps=$(echo "$single_output" | grep "events per second" | awk '{print $NF}')
    local single_latency=$(echo "$single_output" | grep "avg:" | awk '{print $2}')
    
    echo -e "  ${CHECK} Events per second: ${BOLD}${GREEN}${single_eps}${RESET}"
    echo -e "  ${CHECK} Total events:      ${single_events}"
    echo -e "  ${CHECK} Avg latency:       ${single_latency}ms"
    
    echo "    \"single_thread\": {" >> "$json_file"
    echo "      \"threads\": 1," >> "$json_file"
    echo "      \"events_per_second\": ${single_eps:-0}," >> "$json_file"
    echo "      \"total_events\": ${single_events:-0}," >> "$json_file"
    echo "      \"avg_latency_ms\": ${single_latency:-0}" >> "$json_file"
    echo "    }," >> "$json_file"
    
    # ─────────────────────────────────────────────────────────────────────────
    # Multi-threaded test
    # ─────────────────────────────────────────────────────────────────────────
    
    log_section "Multi-Threaded Performance ($CPU_THREADS threads)"
    log "Running multi-thread CPU test..." STEP
    
    local multi_output=$(sysbench cpu \
        --cpu-max-prime=$CPU_PRIME_LIMIT \
        --threads=$CPU_THREADS \
        --time=$CPU_TIME \
        run 2>&1)
    
    local multi_events=$(echo "$multi_output" | grep "total number of events" | awk '{print $NF}')
    local multi_eps=$(echo "$multi_output" | grep "events per second" | awk '{print $NF}')
    local multi_latency=$(echo "$multi_output" | grep "avg:" | awk '{print $2}')
    
    echo -e "  ${CHECK} Events per second: ${BOLD}${GREEN}${multi_eps}${RESET}"
    echo -e "  ${CHECK} Total events:      ${multi_events}"
    echo -e "  ${CHECK} Avg latency:       ${multi_latency}ms"
    
    # Calculate scaling efficiency
    if [[ -n "$single_eps" && -n "$multi_eps" ]]; then
        local scaling=$(echo "scale=2; $multi_eps / $single_eps" | bc 2>/dev/null || echo "N/A")
        local efficiency=$(echo "scale=1; ($multi_eps / $single_eps / $CPU_THREADS) * 100" | bc 2>/dev/null || echo "N/A")
        echo ""
        echo -e "  ${INFO} Scaling factor:    ${BOLD}${scaling}x${RESET}"
        echo -e "  ${INFO} Core efficiency:   ${BOLD}${efficiency}%${RESET}"
    fi
    
    echo "    \"multi_thread\": {" >> "$json_file"
    echo "      \"threads\": $CPU_THREADS," >> "$json_file"
    echo "      \"events_per_second\": ${multi_eps:-0}," >> "$json_file"
    echo "      \"total_events\": ${multi_events:-0}," >> "$json_file"
    echo "      \"avg_latency_ms\": ${multi_latency:-0}," >> "$json_file"
    echo "      \"scaling_factor\": ${scaling:-0}," >> "$json_file"
    echo "      \"core_efficiency_percent\": ${efficiency:-0}" >> "$json_file"
    echo "    }" >> "$json_file"
    
    # Close JSON
    echo "  }" >> "$json_file"
    echo "}" >> "$json_file"
    
    log "CPU benchmark completed" SUCCESS
}
