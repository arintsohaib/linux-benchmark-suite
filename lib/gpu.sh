#!/bin/bash
# ============================================================================
# Linux Benchmark Suite - GPU Benchmark Module
# ============================================================================
# Auto-detects and benchmarks Intel/AMD/NVIDIA GPUs
# Supports: Intel iGPU, AMD Radeon, NVIDIA GeForce/Quadro
# ============================================================================

# Configuration
GPU_TEST_DURATION="${GPU_TEST_DURATION:-10}"

# ============================================================================
# GPU Detection
# ============================================================================

detect_gpu() {
    local gpu_info=""
    local gpu_type="none"
    local gpu_name="Unknown"
    
    # Check for NVIDIA
    if command -v nvidia-smi &>/dev/null; then
        gpu_type="nvidia"
        gpu_name=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1)
    # Check for AMD
    elif [[ -d /sys/class/drm/card0/device ]] && grep -q "amdgpu" /sys/class/drm/card0/device/uevent 2>/dev/null; then
        gpu_type="amd"
        gpu_name=$(cat /sys/class/drm/card0/device/product_name 2>/dev/null || echo "AMD GPU")
    # Check for Intel
    elif [[ -d /sys/class/drm/card0/device ]] && grep -q "i915" /sys/class/drm/card0/device/uevent 2>/dev/null; then
        gpu_type="intel"
        gpu_name=$(lspci | grep -i "VGA\|3D" | grep -i intel | sed 's/.*: //' | head -1)
    # Fallback: check lspci
    elif command -v lspci &>/dev/null; then
        local vga_info=$(lspci | grep -i "VGA\|3D" | head -1)
        if echo "$vga_info" | grep -qi "nvidia"; then
            gpu_type="nvidia"
            gpu_name=$(echo "$vga_info" | sed 's/.*: //')
        elif echo "$vga_info" | grep -qi "amd\|radeon"; then
            gpu_type="amd"
            gpu_name=$(echo "$vga_info" | sed 's/.*: //')
        elif echo "$vga_info" | grep -qi "intel"; then
            gpu_type="intel"
            gpu_name=$(echo "$vga_info" | sed 's/.*: //')
        fi
    fi
    
    echo "$gpu_type|$gpu_name"
}

# ============================================================================
# Intel GPU Benchmark
# ============================================================================

run_intel_gpu_test() {
    local output_dir="$1"
    local results=()
    
    log_section "Intel GPU Benchmark"
    
    # Check for intel-gpu-tools
    if ! command -v intel_gpu_top &>/dev/null; then
        log "Installing intel-gpu-tools..." STEP
        apt-get install -y -qq intel-gpu-tools 2>/dev/null || {
            log "Could not install intel-gpu-tools" WARN
            return 1
        }
    fi
    
    # Get GPU info
    local gpu_info=$(detect_gpu)
    local gpu_name=$(echo "$gpu_info" | cut -d'|' -f2)
    
    echo -e "  ${BOLD}GPU:${RESET} $gpu_name"
    echo ""
    
    # Check for Video Acceleration
    log "Checking video acceleration (VA-API)..." STEP
    local vaapi_supported="false"
    local vaapi_profiles=0
    
    if command -v vainfo &>/dev/null; then
        local vainfo_output=$(vainfo 2>/dev/null)
        if [[ -n "$vainfo_output" ]]; then
            vaapi_supported="true"
            vaapi_profiles=$(echo "$vainfo_output" | grep -c "VAProfile" 2>/dev/null || echo "0")
            echo -e "  ${CHECK} VA-API: $vaapi_profiles profiles available"
        else
            echo -e "  ${CROSS} VA-API: Not available"
        fi
    else
        echo -e "  ${DIM}  vainfo not installed${RESET}"
    fi
    
    # Check OpenCL support
    log "Checking OpenCL compute..." STEP
    local opencl_supported="false"
    local opencl_version=""
    
    if command -v clinfo &>/dev/null; then
        local clinfo_output=$(clinfo 2>/dev/null)
        if echo "$clinfo_output" | grep -q "Device Type.*GPU"; then
            opencl_supported="true"
            opencl_version=$(echo "$clinfo_output" | grep "OpenCL C" | head -1 | awk '{print $NF}')
            local compute_units=$(echo "$clinfo_output" | grep "Max compute units" | awk '{print $NF}')
            echo -e "  ${CHECK} OpenCL: v$opencl_version ($compute_units compute units)"
        else
            echo -e "  ${CROSS} OpenCL GPU: Not detected"
        fi
    else
        echo -e "  ${DIM}  clinfo not installed${RESET}"
    fi
    
    # GPU Frequency Info
    log "Reading GPU frequency..." STEP
    local min_freq=0
    local max_freq=0
    local cur_freq=0
    
    if [[ -f /sys/class/drm/card0/gt_min_freq_mhz ]]; then
        min_freq=$(cat /sys/class/drm/card0/gt_min_freq_mhz 2>/dev/null || echo 0)
        max_freq=$(cat /sys/class/drm/card0/gt_max_freq_mhz 2>/dev/null || echo 0)
        cur_freq=$(cat /sys/class/drm/card0/gt_cur_freq_mhz 2>/dev/null || echo 0)
        echo -e "  ${CHECK} Frequency: ${cur_freq}MHz (min: ${min_freq}, max: ${max_freq})"
    fi
    
    # Run glxgears if available (simple GPU render test)
    log "Running render test..." STEP
    local render_fps=0
    
    if command -v glxgears &>/dev/null && [[ -n "$DISPLAY" ]]; then
        render_fps=$(timeout 5 glxgears -info 2>/dev/null | grep -oP '\d+\.\d+ FPS' | head -1 | grep -oP '\d+' || echo 0)
        if [[ "$render_fps" -gt 0 ]]; then
            echo -e "  ${CHECK} Render: ${render_fps} FPS (glxgears)"
        fi
    else
        echo -e "  ${DIM}  Render test: Requires display${RESET}"
    fi
    
    # GPU memory (Intel shares system RAM)
    local gpu_mem_mb=0
    if [[ -f /sys/kernel/debug/dri/0/i915_gem_objects ]]; then
        local gem_output=$(cat /sys/kernel/debug/dri/0/i915_gem_objects 2>/dev/null | grep "total" | awk '{print int($1/1024/1024)}')
        [[ -n "$gem_output" ]] && gpu_mem_mb=$gem_output
    fi
    
    # Generate JSON output
    cat > "$output_dir/gpu.json" << GPUJSON
{
  "test_type": "gpu",
  "timestamp": "$(date -Iseconds)",
  "gpu": {
    "type": "intel",
    "name": "$gpu_name",
    "driver": "i915"
  },
  "frequency": {
    "current_mhz": $cur_freq,
    "min_mhz": $min_freq,
    "max_mhz": $max_freq
  },
  "capabilities": {
    "vaapi_supported": $vaapi_supported,
    "vaapi_profiles": $vaapi_profiles,
    "opencl_supported": $opencl_supported,
    "opencl_version": "$opencl_version"
  },
  "benchmark": {
    "render_fps": $render_fps,
    "gpu_memory_mb": $gpu_mem_mb
  }
}
GPUJSON
    
    log "Intel GPU benchmark completed" SUCCESS
}

# ============================================================================
# AMD GPU Benchmark
# ============================================================================

run_amd_gpu_test() {
    local output_dir="$1"
    
    log_section "AMD GPU Benchmark"
    
    local gpu_info=$(detect_gpu)
    local gpu_name=$(echo "$gpu_info" | cut -d'|' -f2)
    
    echo -e "  ${BOLD}GPU:${RESET} $gpu_name"
    echo ""
    
    # Check for radeontop
    if command -v radeontop &>/dev/null; then
        log "AMD GPU monitoring available (radeontop)" SUCCESS
    else
        log "radeontop not installed" WARN
    fi
    
    # GPU Info from sysfs
    local gpu_temp=0
    local gpu_power=0
    local gpu_freq=0
    
    if [[ -f /sys/class/drm/card0/device/hwmon/hwmon*/temp1_input ]]; then
        gpu_temp=$(($(cat /sys/class/drm/card0/device/hwmon/hwmon*/temp1_input 2>/dev/null | head -1) / 1000))
        echo -e "  ${CHECK} Temperature: ${gpu_temp}°C"
    fi
    
    if [[ -f /sys/class/drm/card0/device/hwmon/hwmon*/power1_average ]]; then
        gpu_power=$(($(cat /sys/class/drm/card0/device/hwmon/hwmon*/power1_average 2>/dev/null | head -1) / 1000000))
        echo -e "  ${CHECK} Power: ${gpu_power}W"
    fi
    
    # OpenCL check
    local opencl_supported="false"
    if command -v clinfo &>/dev/null; then
        if clinfo 2>/dev/null | grep -q "AMD"; then
            opencl_supported="true"
            echo -e "  ${CHECK} OpenCL: Available"
        fi
    fi
    
    # Generate JSON
    cat > "$output_dir/gpu.json" << GPUJSON
{
  "test_type": "gpu",
  "timestamp": "$(date -Iseconds)",
  "gpu": {
    "type": "amd",
    "name": "$gpu_name",
    "driver": "amdgpu"
  },
  "sensors": {
    "temperature_c": $gpu_temp,
    "power_w": $gpu_power
  },
  "capabilities": {
    "opencl_supported": $opencl_supported
  }
}
GPUJSON
    
    log "AMD GPU benchmark completed" SUCCESS
}

# ============================================================================
# NVIDIA GPU Benchmark
# ============================================================================

run_nvidia_gpu_test() {
    local output_dir="$1"
    
    log_section "NVIDIA GPU Benchmark"
    
    if ! command -v nvidia-smi &>/dev/null; then
        log "nvidia-smi not found" ERROR
        return 1
    fi
    
    # Get detailed GPU info
    local gpu_name=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1)
    local gpu_driver=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -1)
    local gpu_mem_total=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null | head -1)
    local gpu_mem_used=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits 2>/dev/null | head -1)
    local gpu_temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader 2>/dev/null | head -1)
    local gpu_power=$(nvidia-smi --query-gpu=power.draw --format=csv,noheader,nounits 2>/dev/null | head -1 | cut -d'.' -f1)
    local gpu_util=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -1)
    local cuda_version=$(nvidia-smi --query-gpu=pci.bus_id --format=csv,noheader 2>/dev/null && nvidia-smi | grep "CUDA Version" | awk '{print $NF}')
    
    echo -e "  ${BOLD}GPU:${RESET} $gpu_name"
    echo -e "  ${BOLD}Driver:${RESET} $gpu_driver"
    echo -e "  ${BOLD}VRAM:${RESET} ${gpu_mem_used}MB / ${gpu_mem_total}MB"
    echo -e "  ${BOLD}Temp:${RESET} ${gpu_temp}°C"
    echo -e "  ${BOLD}Power:${RESET} ${gpu_power}W"
    echo ""
    
    # CUDA check
    local cuda_supported="false"
    if command -v nvcc &>/dev/null || [[ -d /usr/local/cuda ]]; then
        cuda_supported="true"
        echo -e "  ${CHECK} CUDA: Available"
    fi
    
    # Generate JSON
    cat > "$output_dir/gpu.json" << GPUJSON
{
  "test_type": "gpu",
  "timestamp": "$(date -Iseconds)",
  "gpu": {
    "type": "nvidia",
    "name": "$gpu_name",
    "driver": "$gpu_driver"
  },
  "memory": {
    "total_mb": $gpu_mem_total,
    "used_mb": $gpu_mem_used
  },
  "sensors": {
    "temperature_c": $gpu_temp,
    "power_w": $gpu_power,
    "utilization_percent": $gpu_util
  },
  "capabilities": {
    "cuda_supported": $cuda_supported
  }
}
GPUJSON
    
    log "NVIDIA GPU benchmark completed" SUCCESS
}

# ============================================================================
# Main GPU Benchmark Entry Point
# ============================================================================

run_gpu_test() {
    local output_dir="${1:-${RESULT_DIR:-output}}"
    
    log_header "GPU Performance Benchmark"
    
    # Detect GPU type
    log "Detecting GPU..." STEP
    local gpu_info=$(detect_gpu)
    local gpu_type=$(echo "$gpu_info" | cut -d'|' -f1)
    local gpu_name=$(echo "$gpu_info" | cut -d'|' -f2)
    
    if [[ "$gpu_type" == "none" ]]; then
        log "No GPU detected" WARN
        
        # Create empty JSON
        cat > "$output_dir/gpu.json" << GPUJSON
{
  "test_type": "gpu",
  "timestamp": "$(date -Iseconds)",
  "gpu": {
    "type": "none",
    "name": "No GPU detected"
  },
  "error": "No compatible GPU found"
}
GPUJSON
        return 1
    fi
    
    echo -e "  Detected: ${BOLD}$gpu_name${RESET} ($gpu_type)"
    echo ""
    
    case "$gpu_type" in
        intel)
            run_intel_gpu_test "$output_dir"
            ;;
        amd)
            run_amd_gpu_test "$output_dir"
            ;;
        nvidia)
            run_nvidia_gpu_test "$output_dir"
            ;;
    esac
}
