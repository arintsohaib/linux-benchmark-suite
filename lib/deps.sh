#!/bin/bash
# ============================================================================
# Linux Benchmark Suite - Dependency Management
# ============================================================================
# Auto-detect and install required packages for benchmarking
# ============================================================================

# Required packages
REQUIRED_PKGS=(
    sysbench
    fio
    stress-ng
    linux-cpupower
    jq
    bc
    lsb-release
)

# Package descriptions for display
declare -A PKG_DESC=(
    [sysbench]="CPU & memory benchmarking"
    [fio]="Flexible I/O tester"
    [stress-ng]="System stress testing"
    [linux-cpupower]="CPU frequency management"
    [jq]="JSON processing"
    [bc]="Arbitrary precision calculator"
    [lsb-release]="Linux Standard Base info"
)

# ============================================================================
# Check and Install Dependencies
# ============================================================================

check_dependencies() {
    log_section "Dependency Check"
    
    local missing=()
    local installed=()
    
    for pkg in "${REQUIRED_PKGS[@]}"; do
        if dpkg -s "$pkg" &>/dev/null; then
            installed+=("$pkg")
            echo -e "  ${CHECK} ${pkg} ${DIM}(${PKG_DESC[$pkg]})${RESET}"
        else
            missing+=("$pkg")
            echo -e "  ${CROSS} ${pkg} ${DIM}(${PKG_DESC[$pkg]})${RESET} ${YELLOW}[missing]${RESET}"
        fi
    done
    
    echo ""
    
    if [[ ${#missing[@]} -eq 0 ]]; then
        log "All dependencies installed" SUCCESS
        return 0
    else
        log "${#missing[@]} missing package(s): ${missing[*]}" WARN
        return 1
    fi
}

install_dependencies() {
    local missing=()
    
    # Find missing packages
    for pkg in "${REQUIRED_PKGS[@]}"; do
        if ! dpkg -s "$pkg" &>/dev/null; then
            missing+=("$pkg")
        fi
    done
    
    if [[ ${#missing[@]} -eq 0 ]]; then
        return 0
    fi
    
    # Check if we should prompt the user
    if [[ "$NO_INTERACTIVE" != true ]]; then
        echo ""
        read -p "$(echo -e "  ${BOLD}Missing dependencies detected. Install them now? [Y/n]:${RESET} ")" ans
        if [[ "${ans,,}" == "n" ]]; then
            log "Cannot proceed without dependencies. Exiting." ERROR
            exit 1
        fi
    fi
    
    log "Installing missing packages: ${missing[*]}" STEP
    
    # Update package list
    echo -e "  ${ARROW} Updating package list..."
    apt-get update -qq
    
    # Install missing packages
    echo -e "  ${ARROW} Installing packages..."
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${missing[@]}"
    
    if [[ $? -eq 0 ]]; then
        log "All packages installed successfully" SUCCESS
    else
        log "Some packages failed to install" ERROR
        exit 1
    fi
}

uninstall_dependencies() {
    log_section "Uninstall Dependencies"
    
    echo -e "  ${BOLD}The following packages will be removed:${RESET}"
    echo -e "  ${DIM}${REQUIRED_PKGS[*]}${RESET}"
    echo ""
    
    read -p "$(echo -e "  ${BOLD}${RED}Are you sure you want to uninstall these packages? [y/N]:${RESET} ")" ans
    if [[ "${ans,,}" == "y" ]]; then
        log "Uninstalling dependencies..." STEP
        
        DEBIAN_FRONTEND=noninteractive apt-get remove -y "${REQUIRED_PKGS[@]}"
        DEBIAN_FRONTEND=noninteractive apt-get autoremove -y
        
        log "Dependencies uninstalled successfully" SUCCESS
    else
        log "Skipping uninstallation" INFO
    fi
}

# ============================================================================
# Upgrade and Reboot Handling
# ============================================================================

maybe_upgrade_and_reboot() {
    log_section "System Upgrade Check"
    
    apt-get update -qq
    local upgrades=$(apt list --upgradable 2>/dev/null | wc -l)
    
    if [[ $upgrades -gt 1 ]]; then
        local upgrade_count=$((upgrades - 1))
        log "$upgrade_count package(s) can be upgraded" WARN
        
        echo ""
        echo -e "${YELLOW}┌────────────────────────────────────────────────────────────┐${RESET}"
        echo -e "${YELLOW}│${RESET}  System upgrades are available.                            ${YELLOW}│${RESET}"
        echo -e "${YELLOW}│${RESET}  Upgrading before benchmarking ensures accurate results.   ${YELLOW}│${RESET}"
        echo -e "${YELLOW}└────────────────────────────────────────────────────────────┘${RESET}"
        echo ""
        
        read -p "$(echo -e "${BOLD}Upgrade system before benchmark? [y/N]:${RESET} ")" ans
        
        if [[ "${ans,,}" == "y" ]]; then
            log "Starting system upgrade..." STEP
            
            DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
            
            # Check if reboot is required
            if [[ -f /var/run/reboot-required ]]; then
                log "Upgrade completed. Reboot required for kernel/library changes." WARN
                
                # Save state for resume
                save_state "POST_UPGRADE"
                
                echo ""
                echo -e "${YELLOW}┌────────────────────────────────────────────────────────────────────────┐${RESET}"
                echo -e "${YELLOW}│${RESET}  ${BOLD}System Reboot Required${RESET}                                                ${YELLOW}│${RESET}"
                echo -e "${YELLOW}│${RESET}                                                                        ${YELLOW}│${RESET}"
                echo -e "${YELLOW}│${RESET}  The system upgrade installed updates that require a restart.          ${YELLOW}│${RESET}"
                echo -e "${YELLOW}│${RESET}  Please reboot the server and ${BOLD}run this script again${RESET} to continue.      ${YELLOW}│${RESET}"
                echo -e "${YELLOW}└────────────────────────────────────────────────────────────────────────┘${RESET}"
                echo ""
                
                read -p "$(echo -e "${BOLD}Reboot now? [y/N]:${RESET} ")" reboot_ans
                if [[ "${reboot_ans,,}" == "y" ]]; then
                    log "Rebooting system..." STEP
                    reboot
                else
                    echo ""
                    log "Please remember to reboot manually and re-run the script!" WARN
                    exit 0
                fi
            else
                log "Upgrade completed. No reboot required." SUCCESS
            fi
        else
            log "Skipping system upgrade" INFO
        fi
    else
        log "System is up to date" SUCCESS
    fi
}

# ============================================================================
# Resume from Reboot
# ============================================================================

check_resume() {
    local state=$(load_state)
    
    if [[ "$state" == "POST_UPGRADE" ]]; then
        log "Resuming after system upgrade..." INFO
        clear_state
        return 0
    fi
    
    return 0
}
