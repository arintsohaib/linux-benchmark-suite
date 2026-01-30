#!/bin/bash
# ============================================================================
# Linux Benchmark Suite - Disk I/O Benchmarks
# ============================================================================
# Disk performance testing using fio
# ============================================================================

# ============================================================================
# Disk Benchmark Configuration
# ============================================================================

DISK_SIZE="1G"
DISK_RUNTIME=30
DISK_TEST_DIR="${DISK_TEST_DIR:-$SCRIPT_DIR/tmp_disk_test}"

# ============================================================================
# Run Disk Benchmark
# ============================================================================

run_disk_test() {
    log_header "Disk I/O Performance Benchmark"
    
    local output_dir="${RESULT_DIR:-output}"
    local json_file="$output_dir/disk.json"
    
    # Create directories
    mkdir -p "$DISK_TEST_DIR"
    mkdir -p "$output_dir"
    
    echo -e "  ${BOLD}Test size:${RESET}   $DISK_SIZE"
    echo -e "  ${BOLD}Duration:${RESET}    ${DISK_RUNTIME}s per test"
    echo -e "  ${BOLD}Test path:${RESET}   $DISK_TEST_DIR"
    echo ""
    
    # Check O_DIRECT support
    local fio_direct=1
    local odirect_test_log="$(mktemp)"
    if ! fio --name=odirect_test --directory="$DISK_TEST_DIR" --size=1M --rw=read --direct=1 --ioengine=libaio --output-format=json &> "$odirect_test_log"; then
        log "System does not support O_DIRECT (common in containers). Falling back to direct=0." WARN
        fio_direct=0
    fi
    rm -f "$odirect_test_log"
    
    # Initialize JSON
    echo "{" > "$json_file"
    echo "  \"test_type\": \"disk\"," >> "$json_file"
    echo "  \"timestamp\": \"$(date -Iseconds)\"," >> "$json_file"
    echo "  \"config\": {" >> "$json_file"
    echo "    \"size\": \"$DISK_SIZE\"," >> "$json_file"
    echo "    \"runtime_seconds\": $DISK_RUNTIME," >> "$json_file"
    echo "    \"test_path\": \"$DISK_TEST_DIR\"" >> "$json_file"
    echo "  }," >> "$json_file"
    echo "  \"results\": {" >> "$json_file"
    
    # ─────────────────────────────────────────────────────────────────────────
    # Sequential Read
    # ─────────────────────────────────────────────────────────────────────────
    
    log_section "Sequential Read (1M blocks)"
    log "Running sequential read test..." STEP
    
    local seq_read_log="$(mktemp)"
    if ! fio --name=seq_read \
        --directory="$DISK_TEST_DIR" \
        --size=$DISK_SIZE \
        --time_based \
        --runtime=$DISK_RUNTIME \
        --rw=read \
        --bs=1M \
        --ioengine=libaio \
        --direct=$fio_direct \
        --numjobs=1 \
        --group_reporting \
        --output-format=json \
        --output="$seq_read_json" \
        &> "$seq_read_log"; then
        
        log "Sequential read test failed. See error below:" ERROR
        cat "$seq_read_log" | sed 's/^/    /'
    fi
    rm -f "$seq_read_log"
    
    local seq_read_bw=$(jq -r '.jobs[0].read.bw_bytes // 0' "$seq_read_json" 2>/dev/null)
    local seq_read_iops=$(jq -r '.jobs[0].read.iops // 0' "$seq_read_json" 2>/dev/null)
    local seq_read_lat=$(jq -r '.jobs[0].read.lat_ns.mean // 0' "$seq_read_json" 2>/dev/null)
    
    local seq_read_mb=$(echo "scale=2; $seq_read_bw / 1048576" | bc 2>/dev/null || echo "0")
    local seq_read_lat_ms=$(echo "scale=3; $seq_read_lat / 1000000" | bc 2>/dev/null || echo "0")
    
    echo -e "  ${CHECK} Bandwidth:  ${BOLD}${GREEN}${seq_read_mb} MB/s${RESET}"
    echo -e "  ${CHECK} IOPS:       ${seq_read_iops}"
    echo -e "  ${CHECK} Latency:    ${seq_read_lat_ms}ms"
    
    echo "    \"sequential_read\": {" >> "$json_file"
    echo "      \"bandwidth_mbps\": ${seq_read_mb:-0}," >> "$json_file"
    echo "      \"iops\": ${seq_read_iops:-0}," >> "$json_file"
    echo "      \"latency_ms\": ${seq_read_lat_ms:-0}" >> "$json_file"
    echo "    }," >> "$json_file"
    
    # ─────────────────────────────────────────────────────────────────────────
    # Sequential Write
    # ─────────────────────────────────────────────────────────────────────────
    
    log_section "Sequential Write (1M blocks)"
    log "Running sequential write test..." STEP
    
    local seq_write_log="$(mktemp)"
    if ! fio --name=seq_write \
        --directory="$DISK_TEST_DIR" \
        --size=$DISK_SIZE \
        --time_based \
        --runtime=$DISK_RUNTIME \
        --rw=write \
        --bs=1M \
        --ioengine=libaio \
        --direct=$fio_direct \
        --numjobs=1 \
        --group_reporting \
        --output-format=json \
        --output="$seq_write_json" \
        &> "$seq_write_log"; then
        
        log "Sequential write test failed. See error below:" ERROR
        cat "$seq_write_log" | sed 's/^/    /'
    fi
    rm -f "$seq_write_log"
    
    local seq_write_bw=$(jq -r '.jobs[0].write.bw_bytes // 0' "$seq_write_json" 2>/dev/null)
    local seq_write_iops=$(jq -r '.jobs[0].write.iops // 0' "$seq_write_json" 2>/dev/null)
    local seq_write_lat=$(jq -r '.jobs[0].write.lat_ns.mean // 0' "$seq_write_json" 2>/dev/null)
    
    local seq_write_mb=$(echo "scale=2; $seq_write_bw / 1048576" | bc 2>/dev/null || echo "0")
    local seq_write_lat_ms=$(echo "scale=3; $seq_write_lat / 1000000" | bc 2>/dev/null || echo "0")
    
    echo -e "  ${CHECK} Bandwidth:  ${BOLD}${GREEN}${seq_write_mb} MB/s${RESET}"
    echo -e "  ${CHECK} IOPS:       ${seq_write_iops}"
    echo -e "  ${CHECK} Latency:    ${seq_write_lat_ms}ms"
    
    echo "    \"sequential_write\": {" >> "$json_file"
    echo "      \"bandwidth_mbps\": ${seq_write_mb:-0}," >> "$json_file"
    echo "      \"iops\": ${seq_write_iops:-0}," >> "$json_file"
    echo "      \"latency_ms\": ${seq_write_lat_ms:-0}" >> "$json_file"
    echo "    }," >> "$json_file"
    
    # ─────────────────────────────────────────────────────────────────────────
    # Random Read (4K)
    # ─────────────────────────────────────────────────────────────────────────
    
    log_section "Random Read (4K blocks)"
    log "Running random read test..." STEP
    
    local rand_read_log="$(mktemp)"
    if ! fio --name=rand_read \
        --directory="$DISK_TEST_DIR" \
        --size=$DISK_SIZE \
        --time_based \
        --runtime=$DISK_RUNTIME \
        --rw=randread \
        --bs=4k \
        --ioengine=libaio \
        --direct=$fio_direct \
        --numjobs=4 \
        --iodepth=32 \
        --group_reporting \
        --output-format=json \
        --output="$rand_read_json" \
        &> "$rand_read_log"; then
        
        log "Random read test failed. See error below:" ERROR
        cat "$rand_read_log" | sed 's/^/    /'
    fi
    rm -f "$rand_read_log"
    
    local rand_read_iops=$(jq -r '.jobs[0].read.iops // 0' "$rand_read_json" 2>/dev/null)
    local rand_read_lat=$(jq -r '.jobs[0].read.lat_ns.mean // 0' "$rand_read_json" 2>/dev/null)
    local rand_read_lat_ms=$(echo "scale=3; $rand_read_lat / 1000000" | bc 2>/dev/null || echo "0")
    
    echo -e "  ${CHECK} IOPS:       ${BOLD}${GREEN}${rand_read_iops}${RESET}"
    echo -e "  ${CHECK} Latency:    ${rand_read_lat_ms}ms"
    
    echo "    \"random_read_4k\": {" >> "$json_file"
    echo "      \"iops\": ${rand_read_iops:-0}," >> "$json_file"
    echo "      \"latency_ms\": ${rand_read_lat_ms:-0}" >> "$json_file"
    echo "    }," >> "$json_file"
    
    # ─────────────────────────────────────────────────────────────────────────
    # Random Write (4K)
    # ─────────────────────────────────────────────────────────────────────────
    
    log_section "Random Write (4K blocks)"
    log "Running random write test..." STEP
    
    local rand_write_log="$(mktemp)"
    if ! fio --name=rand_write \
        --directory="$DISK_TEST_DIR" \
        --size=$DISK_SIZE \
        --time_based \
        --runtime=$DISK_RUNTIME \
        --rw=randwrite \
        --bs=4k \
        --ioengine=libaio \
        --direct=$fio_direct \
        --numjobs=4 \
        --iodepth=32 \
        --group_reporting \
        --output-format=json \
        --output="$rand_write_json" \
        &> "$rand_write_log"; then
        
        log "Random write test failed. See error below:" ERROR
        cat "$rand_write_log" | sed 's/^/    /'
    fi
    rm -f "$rand_write_log"
    
    local rand_write_iops=$(jq -r '.jobs[0].write.iops // 0' "$rand_write_json" 2>/dev/null)
    local rand_write_lat=$(jq -r '.jobs[0].write.lat_ns.mean // 0' "$rand_write_json" 2>/dev/null)
    local rand_write_lat_ms=$(echo "scale=3; $rand_write_lat / 1000000" | bc 2>/dev/null || echo "0")
    
    echo -e "  ${CHECK} IOPS:       ${BOLD}${GREEN}${rand_write_iops}${RESET}"
    echo -e "  ${CHECK} Latency:    ${rand_write_lat_ms}ms"
    
    echo "    \"random_write_4k\": {" >> "$json_file"
    echo "      \"iops\": ${rand_write_iops:-0}," >> "$json_file"
    echo "      \"latency_ms\": ${rand_write_lat_ms:-0}" >> "$json_file"
    echo "    }" >> "$json_file"
    
    # Close JSON
    echo "  }" >> "$json_file"
    echo "}" >> "$json_file"
    
    # Cleanup
    rm -rf "$DISK_TEST_DIR"
    rm -f "$output_dir"/fio_*.json
    
    log "Disk benchmark completed" SUCCESS
}
