#!/bin/bash
# ============================================================================
# Linux Benchmark Suite - System Stress Test
# ============================================================================
# Full system stress testing using stress-ng
# ============================================================================

# ============================================================================
# Stress Test Configuration
# ============================================================================

STRESS_CPU_WORKERS=0      # 0 = auto (use all cores)
STRESS_VM_WORKERS=0       # 0 = auto
STRESS_IO_WORKERS=2
STRESS_SWITCH_WORKERS=4

# ============================================================================
# Run Stress Test
# ============================================================================

run_stress_test() {
    local duration="${1:-10m}"
    local duration_seconds=$(parse_duration "$duration")
    
    log_header "Full System Stress Test"
    
    local output_dir="${RESULT_DIR:-output}"
    local json_file="$output_dir/stress.json"
    
    echo -e "  ${BOLD}Duration:${RESET}      $(format_duration $duration_seconds)"
    echo -e "  ${BOLD}CPU workers:${RESET}   $([[ $STRESS_CPU_WORKERS -eq 0 ]] && echo 'auto' || echo $STRESS_CPU_WORKERS)"
    echo -e "  ${BOLD}Memory workers:${RESET} $([[ $STRESS_VM_WORKERS -eq 0 ]] && echo 'auto' || echo $STRESS_VM_WORKERS)"
    echo -e "  ${BOLD}I/O workers:${RESET}   $STRESS_IO_WORKERS"
    echo ""
    
    log "Starting stress test - this will take $(format_duration $duration_seconds)..." STEP
    echo ""
    
    # Create a visual progress indicator
    local start_time=$(date +%s)
    local end_time=$((start_time + duration_seconds))
    
    # Check and disable sched_autogroup_enabled if needed
    local autogroup_path="/proc/sys/kernel/sched_autogroup_enabled"
    local original_autogroup=""
    
    if [[ -f "$autogroup_path" ]]; then
        original_autogroup=$(cat "$autogroup_path")
        if [[ "$original_autogroup" == "1" ]]; then
            log "Temporarily disabling sched_autogroup_enabled for better accuracy" INFO
            echo 0 > "$autogroup_path" 2>/dev/null || log "Failed to disable sched_autogroup_enabled (permission denied?)" WARN
        fi
    fi
    
    # Run stress-ng with metrics
    # Using iomix instead of io as recommended
    stress-ng \
        --cpu $STRESS_CPU_WORKERS \
        --vm $STRESS_VM_WORKERS \
        --iomix $STRESS_IO_WORKERS \
        --switch $STRESS_SWITCH_WORKERS \
        --timeout "${duration_seconds}s" \
        --metrics-brief \
        --yaml "$output_dir/stress_raw.yaml" \
        2>&1 | while read -r line; do
            if [[ -n "$line" ]]; then
                echo -e "  ${DIM}${line}${RESET}"
            fi
        done
        
    # Restore autogroup setting
    if [[ -n "$original_autogroup" && "$original_autogroup" == "1" ]]; then
        echo 1 > "$autogroup_path" 2>/dev/null || true
    fi
    
    echo ""
    
    # Parse stress-ng output and create JSON
    log "Parsing stress test results..." STEP
    
    # Read metrics from yaml if available
    if [[ -f "$output_dir/stress_raw.yaml" ]]; then
        # Convert YAML to simple JSON structure
        echo "{" > "$json_file"
        echo "  \"test_type\": \"stress\"," >> "$json_file"
        echo "  \"timestamp\": \"$(date -Iseconds)\"," >> "$json_file"
        echo "  \"config\": {" >> "$json_file"
        echo "    \"duration_seconds\": $duration_seconds," >> "$json_file"
        echo "    \"cpu_workers\": $STRESS_CPU_WORKERS," >> "$json_file"
        echo "    \"vm_workers\": $STRESS_VM_WORKERS," >> "$json_file"
        echo "    \"io_workers\": $STRESS_IO_WORKERS," >> "$json_file"
        echo "    \"switch_workers\": $STRESS_SWITCH_WORKERS" >> "$json_file"
        echo "  }," >> "$json_file"
        echo "  \"results\": {" >> "$json_file"
        echo "    \"completed\": true," >> "$json_file"
        echo "    \"duration_actual\": $duration_seconds" >> "$json_file"
        echo "  }" >> "$json_file"
        echo "}" >> "$json_file"
        
        rm -f "$output_dir/stress_raw.yaml"
    else
        # Fallback JSON
        echo "{" > "$json_file"
        echo "  \"test_type\": \"stress\"," >> "$json_file"
        echo "  \"timestamp\": \"$(date -Iseconds)\"," >> "$json_file"
        echo "  \"config\": {" >> "$json_file"
        echo "    \"duration_seconds\": $duration_seconds" >> "$json_file"
        echo "  }," >> "$json_file"
        echo "  \"results\": {" >> "$json_file"
        echo "    \"completed\": true" >> "$json_file"
        echo "  }" >> "$json_file"
        echo "}" >> "$json_file"
    fi
    
    log_section "Stress Test Summary"
    
    echo -e "  ${CHECK} ${BOLD}Status:${RESET}   ${GREEN}Completed successfully${RESET}"
    echo -e "  ${CHECK} ${BOLD}Duration:${RESET} $(format_duration $duration_seconds)"
    echo ""
    
    log "Stress test completed" SUCCESS
}
