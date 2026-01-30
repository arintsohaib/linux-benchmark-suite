#!/bin/bash
# ============================================================================
#  _     _                    ____                  _                         _    
# | |   (_)_ __  _   ___  __ | __ )  ___ _ __   ___| |__  _ __ ___   __ _ _ __| | __
# | |   | | '_ \| | | \ \/ / |  _ \ / _ \ '_ \ / __| '_ \| '_ ` _ \ / _` | '__| |/ /
# | |___| | | | | |_| |>  <  | |_) |  __/ | | | (__| | | | | | | | | (_| | |  |   < 
# |_____|_|_| |_|\__,_/_/\_\ |____/ \___|_| |_|\___|_| |_|_| |_| |_|\__,_|_|  |_|\_\
#                                                                                   
# Linux Benchmark Suite v1.0.0
# Professional benchmarking framework for Debian-based systems
# https://github.com/arintsohaib/linux-benchmark-suite
# ============================================================================

set -e

# ============================================================================
# Script Directory and Version
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION="1.0.0"

# ============================================================================
# Default Configuration
# ============================================================================

DURATION="10m"
RESULT_DIR="$SCRIPT_DIR/output"
STATE_FILE="/var/tmp/linux-benchmark.state"
SKIP_CPU=false
SKIP_MEMORY=false
SKIP_DISK=false
SKIP_STRESS=false
SKIP_UPGRADE=false
NO_INTERACTIVE=false
WITH_GPU=false

# ============================================================================
# Parse Command Line Arguments
# ============================================================================

show_help() {
    cat << EOF
${BOLD:-}Linux Benchmark Suite v${VERSION}${RESET:-}
Professional benchmarking framework for Debian-based systems

${BOLD:-}USAGE:${RESET:-}
    sudo ./benchmark.sh [OPTIONS]

${BOLD:-}OPTIONS:${RESET:-}
    -d, --duration=TIME     Stress test duration (default: 10m)
                            Supports: 30s, 5m, 1h
    -o, --output=DIR        Output directory (default: ./output)
    
    --skip-cpu              Skip CPU benchmark
    --skip-memory           Skip memory benchmark
    --skip-disk             Skip disk benchmark
    --skip-stress           Skip stress test
    --skip-upgrade          Skip system upgrade check
    
    --with-gpu              Include GPU benchmark (Intel/AMD/NVIDIA)
    
    -y, --yes               Non-interactive mode (auto-yes)
    -h, --help              Show this help message
    -v, --version           Show version

${BOLD:-}EXAMPLES:${RESET:-}
    sudo ./benchmark.sh                     # Run all tests with defaults
    sudo ./benchmark.sh -d 30m              # Run with 30 minute stress test
    sudo ./benchmark.sh --skip-stress       # Run without stress test
    sudo ./benchmark.sh -y --skip-upgrade   # Non-interactive, skip upgrade

${BOLD:-}OUTPUT:${RESET:-}
    Results are saved in the output directory:
    • results.txt   - Human readable text report
    • results.json  - Machine readable JSON data
    • results.html  - Visual HTML report with charts

EOF
}

show_version() {
    echo "Linux Benchmark Suite v${VERSION}"
    echo "https://github.com/arintsohaib/linux-benchmark-suite"
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--duration)
            DURATION="$2"
            shift 2
            ;;
        --duration=*)
            DURATION="${1#*=}"
            shift
            ;;
        -o|--output)
            RESULT_DIR="$2"
            shift 2
            ;;
        --output=*)
            RESULT_DIR="${1#*=}"
            shift
            ;;
        --skip-cpu)
            SKIP_CPU=true
            shift
            ;;
        --skip-memory)
            SKIP_MEMORY=true
            shift
            ;;
        --skip-disk)
            SKIP_DISK=true
            shift
            ;;
        --skip-stress)
            SKIP_STRESS=true
            shift
            ;;
        --skip-upgrade)
            SKIP_UPGRADE=true
            shift
            ;;
        --with-gpu)
            WITH_GPU=true
            shift
            ;;
        -y|--yes)
            NO_INTERACTIVE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--version)
            show_version
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# ============================================================================
# Load Library Modules
# ============================================================================

source "$SCRIPT_DIR/lib/utils.sh"
source "$SCRIPT_DIR/lib/deps.sh"
source "$SCRIPT_DIR/lib/cpu.sh"
source "$SCRIPT_DIR/lib/memory.sh"
source "$SCRIPT_DIR/lib/disk.sh"
source "$SCRIPT_DIR/lib/stress.sh"
source "$SCRIPT_DIR/lib/gpu.sh"
source "$SCRIPT_DIR/lib/report.sh"

# Export for use in modules
export RESULT_DIR
export SCRIPT_DIR
export NO_INTERACTIVE

# ============================================================================
# Main Entry Point
# ============================================================================

main() {
    # Create output directory
    mkdir -p "$RESULT_DIR"
    
    # Clear screen if running in terminal
    if [[ -t 1 ]]; then
        clear
    fi
    echo ""
    echo -e "${BOLD}${MAGENTA}"
    cat << 'BANNER'
  _     _                    ____                  _                         _    
 | |   (_)_ __  _   ___  __ | __ )  ___ _ __   ___| |__  _ __ ___   __ _ _ __| | __
 | |   | | '_ \| | | \ \/ / |  _ \ / _ \ '_ \ / __| '_ \| '_ ` _ \ / _` | '__| |/ /
 | |___| | | | | |_| |>  <  | |_) |  __/ | | | (__| | | | | | | | | (_| | |  |   < 
 |_____|_|_| |_|\__,_/_/\_\ |____/ \___|_| |_|\___|_| |_|_| |_| |_|\__,_|_|  |_|\_\
BANNER
    echo -e "${RESET}"
    echo -e "  ${DIM}Professional System Benchmarking Suite v${VERSION}${RESET}"
    echo -e "  ${DIM}https://github.com/arintsohaib/linux-benchmark-suite${RESET}"
    echo ""
    
    log "Benchmark suite starting" INFO
    log "Output directory: $RESULT_DIR" INFO
    log "Stress test duration: $DURATION" INFO
    
    # ─────────────────────────────────────────────────────────────────────────
    # Pre-flight Checks
    # ─────────────────────────────────────────────────────────────────────────
    
    check_root
    check_dependencies
    install_dependencies
    set_cpu_performance
    
    if [[ "$SKIP_UPGRADE" != true ]]; then
        maybe_upgrade_and_reboot
    fi
    
    # ─────────────────────────────────────────────────────────────────────────
    # System Information
    # ─────────────────────────────────────────────────────────────────────────
    
    print_system_info
    get_system_info "$RESULT_DIR/system.json"
    
    # ─────────────────────────────────────────────────────────────────────────
    # Run Benchmarks
    # ─────────────────────────────────────────────────────────────────────────
    
    if [[ "$SKIP_CPU" != true ]]; then
        cooldown 5 "Preparing for CPU benchmark"
        run_cpu_test
    else
        log "Skipping CPU benchmark" INFO
    fi
    
    if [[ "$SKIP_MEMORY" != true ]]; then
        cooldown 10 "Preparing for memory benchmark"
        run_memory_test
    else
        log "Skipping memory benchmark" INFO
    fi
    
    if [[ "$SKIP_DISK" != true ]]; then
        cooldown 10 "Preparing for disk benchmark"
        run_disk_test
    else
        log "Skipping disk benchmark" INFO
    fi
    
    if [[ "$SKIP_STRESS" != true ]]; then
        cooldown 30 "Preparing for stress test"
        run_stress_test "$DURATION"
    else
        log "Skipping stress test" INFO
    fi
    
    if [[ "$WITH_GPU" == true ]]; then
        cooldown 5 "Preparing for GPU benchmark"
        run_gpu_test "$RESULT_DIR"
    fi
    
    # ─────────────────────────────────────────────────────────────────────────
    # Generate Reports
    # ─────────────────────────────────────────────────────────────────────────
    
    generate_reports
    
    # ─────────────────────────────────────────────────────────────────────────
    # Complete
    # ─────────────────────────────────────────────────────────────────────────
    
    log_header "Benchmark Complete!"
    
    echo -e "  ${BOLD}${GREEN}All benchmarks completed successfully!${RESET}"
    echo ""
    echo -e "  📊 ${BOLD}Results saved to:${RESET}"
    echo -e "     ${CYAN}$RESULT_DIR/results.txt${RESET}   - Text report"
    echo -e "     ${CYAN}$RESULT_DIR/results.json${RESET}  - JSON data"
    echo -e "     ${CYAN}$RESULT_DIR/results.html${RESET}  - Visual HTML report"
    echo ""
    echo -e "  ${DIM}Open results.html in a browser to view the interactive report${RESET}"
    echo ""
    
    # Cleanup state file
    clear_state
    
    exit 0
}

# Run main
main "$@"
