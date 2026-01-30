#!/bin/bash
# ============================================================================
# Linux Benchmark Suite - Memory Benchmarks
# ============================================================================
# Memory performance testing using sysbench
# ============================================================================

# ============================================================================
# Memory Benchmark Configuration
# ============================================================================

MEMORY_BLOCK_SIZE="1K"
MEMORY_TOTAL_SIZE="10G"
MEMORY_TIME=30
MEMORY_THREADS=$(nproc)

# ============================================================================
# Run Memory Benchmark
# ============================================================================

run_memory_test() {
    log_header "Memory Performance Benchmark"
    
    local output_dir="${RESULT_DIR:-output}"
    local json_file="$output_dir/memory.json"
    
    echo -e "  ${BOLD}Block size:${RESET}  $MEMORY_BLOCK_SIZE"
    echo -e "  ${BOLD}Total size:${RESET}  $MEMORY_TOTAL_SIZE"
    echo -e "  ${BOLD}Duration:${RESET}    ${MEMORY_TIME}s per test"
    echo ""
    
    # Initialize JSON
    echo "{" > "$json_file"
    echo "  \"test_type\": \"memory\"," >> "$json_file"
    echo "  \"timestamp\": \"$(date -Iseconds)\"," >> "$json_file"
    echo "  \"config\": {" >> "$json_file"
    echo "    \"block_size\": \"$MEMORY_BLOCK_SIZE\"," >> "$json_file"
    echo "    \"total_size\": \"$MEMORY_TOTAL_SIZE\"," >> "$json_file"
    echo "    \"time_seconds\": $MEMORY_TIME" >> "$json_file"
    echo "  }," >> "$json_file"
    echo "  \"results\": {" >> "$json_file"
    
    # ─────────────────────────────────────────────────────────────────────────
    # Read test
    # ─────────────────────────────────────────────────────────────────────────
    
    log_section "Memory Read Performance"
    log "Running memory read test..." STEP
    
    local read_output=$(sysbench memory \
        --memory-block-size=$MEMORY_BLOCK_SIZE \
        --memory-total-size=$MEMORY_TOTAL_SIZE \
        --memory-oper=read \
        --threads=$MEMORY_THREADS \
        --time=$MEMORY_TIME \
        run 2>&1)
    
    local read_ops=$(echo "$read_output" | grep "Total operations" | awk -F'[()]' '{print $2}' | awk '{print $1}')
    local read_transfer=$(echo "$read_output" | grep "transferred" | awk -F'[()]' '{print $2}')
    local read_latency=$(echo "$read_output" | grep "avg:" | awk '{print $2}')
    
    echo -e "  ${CHECK} Operations/sec: ${BOLD}${GREEN}${read_ops}${RESET}"
    echo -e "  ${CHECK} Throughput:     ${read_transfer}"
    echo -e "  ${CHECK} Avg latency:    ${read_latency}ms"
    
    echo "    \"read\": {" >> "$json_file"
    echo "      \"operations_per_second\": ${read_ops:-0}," >> "$json_file"
    echo "      \"throughput\": \"${read_transfer:-N/A}\"," >> "$json_file"
    echo "      \"avg_latency_ms\": ${read_latency:-0}" >> "$json_file"
    echo "    }," >> "$json_file"
    
    # ─────────────────────────────────────────────────────────────────────────
    # Write test
    # ─────────────────────────────────────────────────────────────────────────
    
    log_section "Memory Write Performance"
    log "Running memory write test..." STEP
    
    local write_output=$(sysbench memory \
        --memory-block-size=$MEMORY_BLOCK_SIZE \
        --memory-total-size=$MEMORY_TOTAL_SIZE \
        --memory-oper=write \
        --threads=$MEMORY_THREADS \
        --time=$MEMORY_TIME \
        run 2>&1)
    
    local write_ops=$(echo "$write_output" | grep "Total operations" | awk -F'[()]' '{print $2}' | awk '{print $1}')
    local write_transfer=$(echo "$write_output" | grep "transferred" | awk -F'[()]' '{print $2}')
    local write_latency=$(echo "$write_output" | grep "avg:" | awk '{print $2}')
    
    echo -e "  ${CHECK} Operations/sec: ${BOLD}${GREEN}${write_ops}${RESET}"
    echo -e "  ${CHECK} Throughput:     ${write_transfer}"
    echo -e "  ${CHECK} Avg latency:    ${write_latency}ms"
    
    echo "    \"write\": {" >> "$json_file"
    echo "      \"operations_per_second\": ${write_ops:-0}," >> "$json_file"
    echo "      \"throughput\": \"${write_transfer:-N/A}\"," >> "$json_file"
    echo "      \"avg_latency_ms\": ${write_latency:-0}" >> "$json_file"
    echo "    }" >> "$json_file"
    
    # Close JSON
    echo "  }" >> "$json_file"
    echo "}" >> "$json_file"
    
    log "Memory benchmark completed" SUCCESS
}
