#!/bin/bash
# ============================================================================
# Linux Benchmark Suite - Utility Functions
# ============================================================================
# Logging, colors, progress indicators, and system utilities
# ============================================================================

# Colors and formatting
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[0;33m'
export BLUE='\033[0;34m'
export MAGENTA='\033[0;35m'
export CYAN='\033[0;36m'
export WHITE='\033[0;37m'
export BOLD='\033[1m'
export DIM='\033[2m'
export RESET='\033[0m'

# Symbols
export CHECK="${GREEN}✓${RESET}"
export CROSS="${RED}✗${RESET}"
export ARROW="${CYAN}→${RESET}"
export WARN="${YELLOW}⚠${RESET}"
export INFO="${BLUE}ℹ${RESET}"

# ============================================================================
# Logging Functions
# ============================================================================

log() {
    local level="${2:-INFO}"
    local color="$WHITE"
    local symbol="$INFO"
    
    case "$level" in
        SUCCESS) color="$GREEN"; symbol="$CHECK" ;;
        ERROR)   color="$RED"; symbol="$CROSS" ;;
        WARN)    color="$YELLOW"; symbol="$WARN" ;;
        INFO)    color="$BLUE"; symbol="$INFO" ;;
        STEP)    color="$CYAN"; symbol="$ARROW" ;;
    esac
    
    echo -e "${DIM}[$(date '+%H:%M:%S')]${RESET} ${symbol} ${color}${1}${RESET}"
}

log_header() {
    echo ""
    echo -e "${BOLD}${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BOLD}${WHITE}  $1${RESET}"
    echo -e "${BOLD}${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
}

log_section() {
    echo ""
    echo -e "${BOLD}${CYAN}▶ $1${RESET}"
    echo -e "${DIM}─────────────────────────────────────────${RESET}"
}

# ============================================================================
# Progress Indicators
# ============================================================================

spinner() {
    local pid=$1
    local msg="${2:-Processing}"
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r${CYAN}${spin:i++%${#spin}:1}${RESET} ${msg}..."
        sleep 0.1
    done
    printf "\r${CHECK} ${msg}... done\n"
}

progress_bar() {
    local current=$1
    local total=$2
    local width=40
    local percentage=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    
    printf "\r${CYAN}["
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "]${RESET} ${BOLD}%3d%%${RESET}" "$percentage"
}

# ============================================================================
# System Functions
# ============================================================================

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log "This script must be run as root" ERROR
        log "Try: sudo $0" WARN
        exit 1
    fi
    log "Root privileges confirmed" SUCCESS
}

set_cpu_performance() {
    if command -v cpupower &>/dev/null; then
        log "Setting CPU governor to performance mode" STEP
        cpupower frequency-set -g performance &>/dev/null 2>&1 || true
        log "CPU governor set to performance" SUCCESS
    else
        log "cpupower not available, skipping governor change" WARN
    fi
}

# ============================================================================
# Cooldown Function with Visual Timer
# ============================================================================

cooldown() {
    local seconds=$1
    local msg="${2:-Cooling down}"
    
    log "$msg for ${seconds}s..." STEP
    
    for ((i=seconds; i>0; i--)); do
        printf "\r${DIM}  ⏳ %02d seconds remaining...${RESET}" "$i"
        sleep 1
    done
    printf "\r${CHECK} Cooldown complete                    \n"
}

# ============================================================================
# System Information Collection
# ============================================================================

get_system_info() {
    local output_file="${1:-/dev/stdout}"
    
    {
        echo "{"
        echo "  \"timestamp\": \"$(date -Iseconds)\","
        echo "  \"hostname\": \"$(hostname)\","
        echo "  \"os\": {"
        echo "    \"name\": \"$(lsb_release -si 2>/dev/null || echo 'Unknown')\","
        echo "    \"version\": \"$(lsb_release -sr 2>/dev/null || echo 'Unknown')\","
        echo "    \"codename\": \"$(lsb_release -sc 2>/dev/null || echo 'Unknown')\","
        echo "    \"kernel\": \"$(uname -r)\""
        echo "  },"
        echo "  \"cpu\": {"
        echo "    \"model\": \"$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs)\","
        echo "    \"cores\": $(nproc),"
        echo "    \"threads\": $(grep -c ^processor /proc/cpuinfo),"
        echo "    \"freq_mhz\": $(grep -m1 'cpu MHz' /proc/cpuinfo | cut -d: -f2 | xargs | cut -d. -f1)"
        echo "  },"
        echo "  \"memory\": {"
        echo "    \"total_mb\": $(free -m | awk '/Mem:/ {print $2}'),"
        echo "    \"available_mb\": $(free -m | awk '/Mem:/ {print $7}')"
        echo "  },"
        echo "  \"disk\": {"
        echo "    \"root_total_gb\": $(df -BG / | awk 'NR==2 {print $2}' | tr -d 'G'),"
        echo "    \"root_available_gb\": $(df -BG / | awk 'NR==2 {print $4}' | tr -d 'G')"
        echo "  }"
        echo "}"
    } > "$output_file"
}

print_system_info() {
    log_section "System Information"
    
    echo -e "  ${BOLD}Hostname:${RESET}    $(hostname)"
    echo -e "  ${BOLD}OS:${RESET}          $(lsb_release -ds 2>/dev/null || echo 'Unknown')"
    echo -e "  ${BOLD}Kernel:${RESET}      $(uname -r)"
    echo -e "  ${BOLD}CPU:${RESET}         $(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs)"
    echo -e "  ${BOLD}Cores:${RESET}       $(nproc) cores / $(grep -c ^processor /proc/cpuinfo) threads"
    echo -e "  ${BOLD}Memory:${RESET}      $(free -h | awk '/Mem:/ {print $2}')"
    echo -e "  ${BOLD}Disk:${RESET}        $(df -h / | awk 'NR==2 {print $2}') total, $(df -h / | awk 'NR==2 {print $4}') available"
    echo ""
}

# ============================================================================
# Time Parsing (e.g., 10m, 1h, 30s)
# ============================================================================

parse_duration() {
    local input="$1"
    local value="${input%[smh]*}"
    local unit="${input##*[0-9]}"
    
    case "$unit" in
        s) echo "$value" ;;
        m) echo $((value * 60)) ;;
        h) echo $((value * 3600)) ;;
        *) echo "$value" ;;  # Default to seconds
    esac
}

format_duration() {
    local seconds=$1
    
    if [[ $seconds -ge 3600 ]]; then
        printf "%dh %dm" $((seconds / 3600)) $(((seconds % 3600) / 60))
    elif [[ $seconds -ge 60 ]]; then
        printf "%dm %ds" $((seconds / 60)) $((seconds % 60))
    else
        printf "%ds" "$seconds"
    fi
}

# ============================================================================
# State Management for Reboot Resume
# ============================================================================

STATE_FILE="${STATE_FILE:-/var/tmp/linux-benchmark.state}"

save_state() {
    local phase="$1"
    echo "BENCHMARK_PHASE=$phase" > "$STATE_FILE"
    echo "BENCHMARK_TIME=$(date +%s)" >> "$STATE_FILE"
}

load_state() {
    if [[ -f "$STATE_FILE" ]]; then
        source "$STATE_FILE"
        echo "$BENCHMARK_PHASE"
    else
        echo "START"
    fi
}

clear_state() {
    rm -f "$STATE_FILE"
}
