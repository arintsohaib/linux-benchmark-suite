# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - 2026-01-30

### 🎉 Initial Release

**Linux Benchmark Suite** - Professional-grade automated benchmarking for Linux servers, desktops, and laptops.

### ✨ Features

- **CPU Benchmarks** - Single-thread and multi-thread performance testing with sysbench
- **Memory Benchmarks** - Read/write bandwidth and operations per second measurement
- **Disk I/O Benchmarks** - Sequential and random I/O, IOPS, and latency testing with fio
- **GPU Benchmarks** - Auto-detection and testing for Intel, AMD, and NVIDIA GPUs
- **Stress Testing** - Full system stability testing with stress-ng
- **Multi-format Reports** - Beautiful HTML, JSON, and TXT output formats
- **Auto-dependency Installation** - Automatically installs required packages
- **Resume Support** - Can resume after system upgrades and reboots

### 🎮 GPU Support (NEW!)

- Intel iGPU (UHD, Iris, Arc) - VA-API profiles, frequency range
- AMD Radeon - Temperature, power draw, OpenCL compute
- NVIDIA GeForce/Quadro - VRAM, CUDA, temperature, utilization

### 📊 Sample Results

Tested on Intel Core i5-12500, 64GB DDR4, Enterprise NVMe:

| Benchmark | Result |
|-----------|--------|
| CPU Single-thread | 1,517 events/sec |
| CPU Multi-thread | 8,537 events/sec |
| Memory Read | 77 GB/s |
| Memory Write | 18.6 GB/s |
| Disk Seq Read | 14.4 GB/s |
| Disk Seq Write | 8.3 GB/s |
| Random 4K IOPS | 3.5M+ |
| GPU VA-API Profiles | 36 |

### 🛠️ Requirements

- Debian 12+, Ubuntu 22.04+, or any apt-based distribution
- Root/sudo access
- Dependencies auto-installed: sysbench, fio, stress-ng, jq

### 🙏 Acknowledgments

Built with amazing open-source tools:
- [sysbench](https://github.com/akopytov/sysbench)
- [fio](https://github.com/axboe/fio)
- [stress-ng](https://github.com/ColinIanKing/stress-ng)
- [Chart.js](https://www.chartjs.org/)
- [intel-gpu-tools](https://gitlab.freedesktop.org/drm/igt-gpu-tools)
