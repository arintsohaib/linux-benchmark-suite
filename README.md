# 🚀 Linux Benchmark Suite

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Debian](https://img.shields.io/badge/Debian-13+-A81D33?logo=debian)](https://www.debian.org/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04+-E95420?logo=ubuntu)](https://ubuntu.com/)
[![Shell](https://img.shields.io/badge/Shell-Bash-4EAA25?logo=gnu-bash)](https://www.gnu.org/software/bash/)

**Professional-grade automated benchmarking framework for Debian-based Linux systems.**

Produces reproducible CPU, memory, disk, and stress-test results with stunning visual HTML reports.

---

## 📈 Sample Results

*Tested on Hetzner Dedicated Server (Intel i5-12500, 64GB RAM, Samsung PM9A1 NVMe)*

| Benchmark | Result | Notes |
|-----------|--------|-------|
| **CPU Single-thread** | 1,521 events/sec | sysbench prime calculation |
| **CPU Multi-thread** | 8,540 events/sec | 12 threads, 5.6x scaling |
| **Memory Read** | 95.9 GB/s | 1KB blocks |
| **Memory Write** | 18.5 GB/s | 1KB blocks |
| **Disk Seq Write** | 8.2 GB/s | Direct I/O, verified |
| **Disk Seq Read** | 13.9 GB/s | Direct I/O, verified |
| **Disk Random 4K** | 900K+ IOPS | Per-core, 4 parallel jobs |

## ✨ Features

- 🔧 **Auto-install dependencies** – Detects and installs missing packages
- 🔄 **Upgrade & reboot detection** – Optional system upgrade with resume support
- ⚡ **Ordered test execution** – CPU → Memory → Disk → Stress with cooldowns
- 📊 **Multi-format reports** – TXT, JSON, and premium HTML with charts
- 🎨 **Beautiful HTML reports** – Dark theme, glassmorphism, Chart.js visualizations
- 🕐 **Configurable duration** – User-defined stress test length
- 📱 **Responsive design** – Mobile-friendly HTML reports

---

## 📦 Quick Start

```bash
# Clone the repository
git clone https://github.com/arintsohaib/linux-benchmark-suite.git
cd linux-benchmark-suite

# Make executable
chmod +x benchmark.sh

# Run with sudo (required for benchmarking)
sudo ./benchmark.sh
```

---

## 🛠️ Usage

```bash
sudo ./benchmark.sh [OPTIONS]
```

### Options

| Option | Description |
|--------|-------------|
| `-d, --duration=TIME` | Stress test duration (default: `10m`). Supports: `30s`, `5m`, `1h` |
| `-o, --output=DIR` | Output directory (default: `./output`) |
| `--skip-cpu` | Skip CPU benchmark |
| `--skip-memory` | Skip memory benchmark |
| `--skip-disk` | Skip disk benchmark |
| `--skip-stress` | Skip stress test |
| `--skip-upgrade` | Skip system upgrade check |
| `-y, --yes` | Non-interactive mode |
| `-h, --help` | Show help message |
| `-v, --version` | Show version |

### Examples

```bash
# Run all benchmarks with defaults (10 minute stress test)
sudo ./benchmark.sh

# Custom stress test duration
sudo ./benchmark.sh --duration=30m

# Quick benchmark without stress test
sudo ./benchmark.sh --skip-stress

# Non-interactive mode for automation
sudo ./benchmark.sh -y --skip-upgrade
```

---

## 📊 Output

Results are saved to the `output/` directory:

| File | Description |
|------|-------------|
| `results.txt` | Human-readable text summary |
| `results.json` | Machine-readable JSON data |
| `results.html` | Interactive visual report with charts |

### HTML Report Features

- 📈 **CPU Charts** – Single vs multi-thread performance comparison
- 🧠 **Memory Visualization** – Read/write operations doughnut chart
- 💾 **Disk I/O Metrics** – Sequential and random IOPS visualization
- 📥 **Export Button** – Download raw JSON data
- 🌙 **Dark Theme** – Modern glassmorphism design

---

## 🔬 What's Tested

### CPU Benchmark
- Single-thread prime calculation (sysbench)
- Multi-thread prime calculation
- Scaling efficiency measurement

### Memory Benchmark
- Read operations per second
- Write operations per second
- Memory bandwidth measurement

### Disk I/O Benchmark
- Sequential read/write (1MB blocks)
- Random read/write (4K blocks)
- IOPS and latency measurements

### Stress Test
- Full CPU stress (all cores)
- Memory stress (all available)
- I/O operations stress
- Context switching stress

---

## 📁 Project Structure

```
linux-benchmark-suite/
├── benchmark.sh           # Main entry point
├── lib/
│   ├── utils.sh          # Logging & utilities
│   ├── deps.sh           # Dependency management
│   ├── cpu.sh            # CPU benchmarks
│   ├── memory.sh         # Memory benchmarks
│   ├── disk.sh           # Disk I/O benchmarks
│   ├── stress.sh         # Stress testing
│   └── report.sh         # Report generation
├── templates/
│   └── report.html       # HTML report template
├── output/               # Generated reports
└── README.md
```

---

## 🖥️ Requirements

- **OS**: Debian 13+ / Ubuntu 22.04+ (or any apt-based distro)
- **Permissions**: Root (sudo)
- **Dependencies** (auto-installed):
  - `sysbench` – CPU & memory benchmarking
  - `fio` – Disk I/O testing
  - `stress-ng` – System stress testing
  - `jq` – JSON processing
  - `bc` – Calculations

---

## 📸 Screenshots

### Terminal Output
```
  _     _                    ____                  _                         _    
 | |   (_)_ __  _   ___  __ | __ )  ___ _ __   ___| |__  _ __ ___   __ _ _ __| | __
 | |   | | '_ \| | | \ \/ / |  _ \ / _ \ '_ \ / __| '_ \| '_ ` _ \ / _` | '__| |/ /
 | |___| | | | | |_| |>  <  | |_) |  __/ | | | (__| | | | | | | | | (_| | |  |   < 
 |_____|_|_| |_|\__,_/_/\_\ |____/ \___|_| |_|\___|_| |_|_| |_| |_|\__,_|_|  |_|\_\

  Professional System Benchmarking Suite v1.0.0

[14:32:05] ✓ Root privileges confirmed
[14:32:05] ✓ All dependencies installed
[14:32:06] → Running single-thread CPU test...
[14:32:36] ✓ Events per second: 1247.53
```

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- [sysbench](https://github.com/akopytov/sysbench) – CPU & memory benchmarking
- [fio](https://github.com/axboe/fio) – Flexible I/O tester
- [stress-ng](https://github.com/ColinIanKing/stress-ng) – Stress testing
- [Chart.js](https://www.chartjs.org/) – Beautiful charts

---

<p align="center">
  Made with ❤️ for the Linux community
</p>
