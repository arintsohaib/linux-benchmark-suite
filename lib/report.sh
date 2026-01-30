#!/bin/bash
# ============================================================================
# Linux Benchmark Suite - Report Generation
# ============================================================================
# Generate TXT, JSON, and premium HTML reports
# ============================================================================

# ============================================================================
# Generate All Reports
# ============================================================================

generate_reports() {
    log_header "Generating Reports"
    
    local output_dir="${RESULT_DIR:-output}"
    
    # Generate combined JSON
    log "Creating combined JSON report..." STEP
    generate_combined_json "$output_dir"
    
    # Generate TXT summary
    log "Creating text summary..." STEP
    generate_txt_report "$output_dir"
    
    # Generate HTML report
    log "Creating HTML report..." STEP
    generate_html_report "$output_dir"
    
    log_section "Reports Generated"
    echo -e "  ${CHECK} ${BOLD}JSON:${RESET}  $output_dir/results.json"
    echo -e "  ${CHECK} ${BOLD}TXT:${RESET}   $output_dir/results.txt"
    echo -e "  ${CHECK} ${BOLD}HTML:${RESET}  $output_dir/results.html"
    echo ""
    
    log "All reports generated successfully" SUCCESS
}

# ============================================================================
# Combined JSON Report
# ============================================================================

generate_combined_json() {
    local output_dir="$1"
    local json_file="$output_dir/results.json"
    
    {
        echo "{"
        echo "  \"benchmark_suite\": \"Linux Benchmark Suite\","
        echo "  \"version\": \"1.0.0\","
        echo "  \"generated_at\": \"$(date -Iseconds)\","
        echo "  \"system\": $(cat "$output_dir/system.json" 2>/dev/null || echo '{}'),"
        echo "  \"cpu\": $(cat "$output_dir/cpu.json" 2>/dev/null || echo '{}'),"
        echo "  \"memory\": $(cat "$output_dir/memory.json" 2>/dev/null || echo '{}'),"
        echo "  \"disk\": $(cat "$output_dir/disk.json" 2>/dev/null || echo '{}'),"
        echo "  \"stress\": $(cat "$output_dir/stress.json" 2>/dev/null || echo '{}')"
        echo "}"
    } > "$json_file"
}

# ============================================================================
# TXT Summary Report
# ============================================================================

generate_txt_report() {
    local output_dir="$1"
    local txt_file="$output_dir/results.txt"
    
    {
        echo "╔══════════════════════════════════════════════════════════════════════╗"
        echo "║                    LINUX BENCHMARK SUITE - RESULTS                   ║"
        echo "╠══════════════════════════════════════════════════════════════════════╣"
        echo "║  Generated: $(date '+%Y-%m-%d %H:%M:%S')                                      ║"
        echo "║  Hostname:  $(hostname | head -c 50)                                             ║"
        echo "╚══════════════════════════════════════════════════════════════════════╝"
        echo ""
        
        # System Info
        echo "┌─────────────────────────────────────────────────────────────────────┐"
        echo "│ SYSTEM INFORMATION                                                   │"
        echo "├─────────────────────────────────────────────────────────────────────┤"
        echo "│ OS:      $(lsb_release -ds 2>/dev/null | head -c 58) │"
        echo "│ Kernel:  $(uname -r | head -c 58) │"
        echo "│ CPU:     $(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs | head -c 50) │"
        echo "│ Cores:   $(nproc) cores / $(grep -c ^processor /proc/cpuinfo) threads                                             │"
        echo "│ RAM:     $(free -h | awk '/Mem:/ {print $2}')                                                │"
        echo "└─────────────────────────────────────────────────────────────────────┘"
        echo ""
        
        # CPU Results
        if [[ -f "$output_dir/cpu.json" ]]; then
            local cpu_single=$(jq -r '.results.single_thread.events_per_second // "N/A"' "$output_dir/cpu.json")
            local cpu_multi=$(jq -r '.results.multi_thread.events_per_second // "N/A"' "$output_dir/cpu.json")
            
            echo "┌─────────────────────────────────────────────────────────────────────┐"
            echo "│ CPU BENCHMARK                                                        │"
            echo "├─────────────────────────────────────────────────────────────────────┤"
            echo "│ Single-thread:  $cpu_single events/sec                               │"
            echo "│ Multi-thread:   $cpu_multi events/sec                                │"
            echo "└─────────────────────────────────────────────────────────────────────┘"
            echo ""
        fi
        
        # Memory Results
        if [[ -f "$output_dir/memory.json" ]]; then
            local mem_read=$(jq -r '.results.read.throughput // "N/A"' "$output_dir/memory.json")
            local mem_write=$(jq -r '.results.write.throughput // "N/A"' "$output_dir/memory.json")
            
            echo "┌─────────────────────────────────────────────────────────────────────┐"
            echo "│ MEMORY BENCHMARK                                                     │"
            echo "├─────────────────────────────────────────────────────────────────────┤"
            echo "│ Read Throughput:   $mem_read                                         │"
            echo "│ Write Throughput:  $mem_write                                        │"
            echo "└─────────────────────────────────────────────────────────────────────┘"
            echo ""
        fi
        
        # Disk Results
        if [[ -f "$output_dir/disk.json" ]]; then
            local disk_seq_read=$(jq -r '.results.sequential_read.bandwidth_mbps // "N/A"' "$output_dir/disk.json")
            local disk_seq_write=$(jq -r '.results.sequential_write.bandwidth_mbps // "N/A"' "$output_dir/disk.json")
            local disk_rand_read=$(jq -r '.results.random_read_4k.iops // "N/A"' "$output_dir/disk.json")
            local disk_rand_write=$(jq -r '.results.random_write_4k.iops // "N/A"' "$output_dir/disk.json")
            
            echo "┌─────────────────────────────────────────────────────────────────────┐"
            echo "│ DISK BENCHMARK                                                       │"
            echo "├─────────────────────────────────────────────────────────────────────┤"
            echo "│ Sequential Read:   $disk_seq_read MB/s                               │"
            echo "│ Sequential Write:  $disk_seq_write MB/s                              │"
            echo "│ Random Read 4K:    $disk_rand_read IOPS                              │"
            echo "│ Random Write 4K:   $disk_rand_write IOPS                             │"
            echo "└─────────────────────────────────────────────────────────────────────┘"
            echo ""
        fi
        
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "                    Generated by Linux Benchmark Suite"
        echo "                   https://github.com/arintsohaib/linux-benchmark-suite"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        
    } > "$txt_file"
}

# ============================================================================
# Premium HTML Report
# ============================================================================

generate_html_report() {
    local output_dir="$1"
    local html_file="$output_dir/results.html"
    local template_dir="${SCRIPT_DIR:-$(dirname "${BASH_SOURCE[0]}")/..}/templates"
    
    # Read JSON data for embedding
    local system_json=$(cat "$output_dir/system.json" 2>/dev/null || echo '{}')
    local cpu_json=$(cat "$output_dir/cpu.json" 2>/dev/null || echo '{}')
    local memory_json=$(cat "$output_dir/memory.json" 2>/dev/null || echo '{}')
    local disk_json=$(cat "$output_dir/disk.json" 2>/dev/null || echo '{}')
    local stress_json=$(cat "$output_dir/stress.json" 2>/dev/null || echo '{}')
    
    # Extract values for display
    local hostname=$(echo "$system_json" | jq -r '.hostname // "Unknown"')
    local os_name=$(echo "$system_json" | jq -r '.os.name // "Unknown"')
    local os_version=$(echo "$system_json" | jq -r '.os.version // ""')
    local kernel=$(echo "$system_json" | jq -r '.os.kernel // "Unknown"')
    local cpu_model=$(echo "$system_json" | jq -r '.cpu.model // "Unknown"')
    local cpu_cores=$(echo "$system_json" | jq -r '.cpu.cores // 0')
    local cpu_threads=$(echo "$system_json" | jq -r '.cpu.threads // 0')
    local mem_total=$(echo "$system_json" | jq -r '.memory.total_mb // 0')
    local disk_total=$(echo "$system_json" | jq -r '.disk.root_total_gb // 0')
    
    local cpu_single=$(echo "$cpu_json" | jq -r '.results.single_thread.events_per_second // 0')
    local cpu_multi=$(echo "$cpu_json" | jq -r '.results.multi_thread.events_per_second // 0')
    local cpu_scaling=$(echo "$cpu_json" | jq -r '.results.multi_thread.scaling_factor // 0')
    
    local mem_read_ops=$(echo "$memory_json" | jq -r '.results.read.operations_per_second // 0')
    local mem_write_ops=$(echo "$memory_json" | jq -r '.results.write.operations_per_second // 0')
    
    local disk_seq_read=$(echo "$disk_json" | jq -r '.results.sequential_read.bandwidth_mbps // 0')
    local disk_seq_write=$(echo "$disk_json" | jq -r '.results.sequential_write.bandwidth_mbps // 0')
    local disk_rand_read=$(echo "$disk_json" | jq -r '.results.random_read_4k.iops // 0')
    local disk_rand_write=$(echo "$disk_json" | jq -r '.results.random_write_4k.iops // 0')
    
    # Use the HTML template
    if [[ -f "$template_dir/report.html" ]]; then
        # Substitute placeholders
        sed -e "s|{{HOSTNAME}}|$hostname|g" \
            -e "s|{{OS_NAME}}|$os_name|g" \
            -e "s|{{OS_VERSION}}|$os_version|g" \
            -e "s|{{KERNEL}}|$kernel|g" \
            -e "s|{{CPU_MODEL}}|$cpu_model|g" \
            -e "s|{{CPU_CORES}}|$cpu_cores|g" \
            -e "s|{{CPU_THREADS}}|$cpu_threads|g" \
            -e "s|{{MEM_TOTAL}}|$mem_total|g" \
            -e "s|{{DISK_TOTAL}}|$disk_total|g" \
            -e "s|{{CPU_SINGLE}}|$cpu_single|g" \
            -e "s|{{CPU_MULTI}}|$cpu_multi|g" \
            -e "s|{{CPU_SCALING}}|$cpu_scaling|g" \
            -e "s|{{MEM_READ_OPS}}|$mem_read_ops|g" \
            -e "s|{{MEM_WRITE_OPS}}|$mem_write_ops|g" \
            -e "s|{{DISK_SEQ_READ}}|$disk_seq_read|g" \
            -e "s|{{DISK_SEQ_WRITE}}|$disk_seq_write|g" \
            -e "s|{{DISK_RAND_READ}}|$disk_rand_read|g" \
            -e "s|{{DISK_RAND_WRITE}}|$disk_rand_write|g" \
            -e "s|{{TIMESTAMP}}|$(date '+%Y-%m-%d %H:%M:%S')|g" \
            -e "s|{{SYSTEM_JSON}}|$(echo "$system_json" | jq -c .)|g" \
            -e "s|{{CPU_JSON}}|$(echo "$cpu_json" | jq -c .)|g" \
            -e "s|{{MEMORY_JSON}}|$(echo "$memory_json" | jq -c .)|g" \
            -e "s|{{DISK_JSON}}|$(echo "$disk_json" | jq -c .)|g" \
            -e "s|{{STRESS_JSON}}|$(echo "$stress_json" | jq -c .)|g" \
            "$template_dir/report.html" > "$html_file"
    else
        log "HTML template not found, generating inline..." WARN
        generate_inline_html "$html_file" "$hostname" "$os_name" "$os_version" "$kernel" \
            "$cpu_model" "$cpu_cores" "$cpu_threads" "$mem_total" "$disk_total" \
            "$cpu_single" "$cpu_multi" "$cpu_scaling" \
            "$mem_read_ops" "$mem_write_ops" \
            "$disk_seq_read" "$disk_seq_write" "$disk_rand_read" "$disk_rand_write"
    fi
}

# Fallback inline HTML generator
generate_inline_html() {
    local output_file="$1"
    shift
    local hostname="$1" os_name="$2" os_version="$3" kernel="$4"
    local cpu_model="$5" cpu_cores="$6" cpu_threads="$7" mem_total="$8" disk_total="$9"
    shift 9
    local cpu_single="$1" cpu_multi="$2" cpu_scaling="$3"
    local mem_read_ops="$4" mem_write_ops="$5"
    local disk_seq_read="$6" disk_seq_write="$7" disk_rand_read="$8" disk_rand_write="$9"
    
    cat > "$output_file" << 'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Linux Benchmark Results</title>
    <style>
        :root {
            --bg-primary: #0f172a;
            --bg-secondary: #1e293b;
            --bg-card: rgba(30, 41, 59, 0.8);
            --text-primary: #f8fafc;
            --text-secondary: #94a3b8;
            --accent: #3b82f6;
            --accent-gradient: linear-gradient(135deg, #3b82f6 0%, #8b5cf6 100%);
            --success: #10b981;
            --warning: #f59e0b;
        }
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
            background: var(--bg-primary);
            color: var(--text-primary);
            min-height: 100vh;
            line-height: 1.6;
        }
        .container { max-width: 1200px; margin: 0 auto; padding: 2rem; }
        .header {
            text-align: center;
            padding: 3rem 0;
            background: var(--accent-gradient);
            border-radius: 1.5rem;
            margin-bottom: 2rem;
        }
        .header h1 { font-size: 2.5rem; margin-bottom: 0.5rem; }
        .header p { color: rgba(255,255,255,0.8); }
        .cards { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 1.5rem; }
        .card {
            background: var(--bg-card);
            backdrop-filter: blur(10px);
            border-radius: 1rem;
            padding: 1.5rem;
            border: 1px solid rgba(255,255,255,0.1);
        }
        .card h3 {
            color: var(--accent);
            margin-bottom: 1rem;
            font-size: 1.1rem;
            text-transform: uppercase;
            letter-spacing: 0.05em;
        }
        .metric { margin-bottom: 1rem; }
        .metric-label { color: var(--text-secondary); font-size: 0.875rem; }
        .metric-value { font-size: 1.5rem; font-weight: 700; color: var(--text-primary); }
        .metric-unit { font-size: 0.875rem; color: var(--text-secondary); }
        .progress-bar {
            height: 8px;
            background: var(--bg-secondary);
            border-radius: 4px;
            margin-top: 0.5rem;
            overflow: hidden;
        }
        .progress-fill {
            height: 100%;
            background: var(--accent-gradient);
            border-radius: 4px;
            transition: width 1s ease-out;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 Linux Benchmark Suite</h1>
            <p>Performance Report</p>
        </div>
        <div class="cards">
            <div class="card">
                <h3>📊 System Info</h3>
                <div class="metric">
                    <div class="metric-label">Hostname</div>
                    <div class="metric-value" style="font-size:1.2rem">Benchmark Host</div>
                </div>
            </div>
            <div class="card">
                <h3>⚡ CPU Performance</h3>
                <div class="metric">
                    <div class="metric-label">Single Thread</div>
                    <div class="metric-value">-<span class="metric-unit"> events/sec</span></div>
                </div>
                <div class="metric">
                    <div class="metric-label">Multi Thread</div>
                    <div class="metric-value">-<span class="metric-unit"> events/sec</span></div>
                </div>
            </div>
            <div class="card">
                <h3>💾 Disk I/O</h3>
                <div class="metric">
                    <div class="metric-label">Sequential Read</div>
                    <div class="metric-value">-<span class="metric-unit"> MB/s</span></div>
                </div>
                <div class="metric">
                    <div class="metric-label">Random 4K IOPS</div>
                    <div class="metric-value">-</div>
                </div>
            </div>
        </div>
    </div>
</body>
</html>
HTMLEOF
}
