# SysmonElixir — System Monitor HTTP Service in Elixir

A lightweight Elixir script (no Mix project) that exposes Linux system metrics over HTTP.  
Endpoints:
- **GET /health** — returns `ok`  
- **GET /metrics** — returns JSON `{ cpu_percent, memory_used_mb, disk_used_pct }`

🔗 Repository: https://github.com/bocaletto-luca/sysmon-elixir

---

## 🚀 Features

- Real‐time CPU usage (%) via `/proc/stat` snapshot diff  
- Memory used (MB) via `/proc/meminfo`  
- Disk usage (%) via `df -Pk /`  
- HTTP server on port **4000** using **Plug.Cowboy**  
- JSON API with **Jason**  
- Self‐installing dependencies with `Mix.install/1`  
- Single-file script: `app.exs`  

---

## 📋 Prerequisites

- **Elixir ≥ 1.12** (for `Mix.install/1`)  
- A Linux host with `/proc` filesystem and `df` command  

Check your version:

    elixir --version

Clone the repo:

    git clone https://github.com/bocaletto-luca/sysmon-elixir.git
    cd sysmon-elixir

Run the script with Elixir:

    elixir app.exs

You should see:

    🚀 Server running at http://localhost:4000

Health Check

    curl -i http://localhost:4000/health

Response:

    HTTP/1.1 200 OK
    content-type: text/plain; charset=utf-8
    content-length: 2

    ok

Metrics Endpoint

    curl http://localhost:4000/metrics | jq

Example JSON:

    {
    "cpu_percent": 4.7,
    "memory_used_mb": 512.3,
    "disk_used_pct": 35
    }

🛠️ How It Works

    CPU: reads /proc/stat twice with 100 ms delay, computes (1 – Δidle/Δtotal)*100

    Memory: parses MemTotal & MemAvailable from /proc/meminfo

    Disk: invokes df -Pk / and extracts the Use% column

    HTTP: Plug.Router routes requests to handlers and encodes JSON with Jason

Contributing

    Fork the repo

    Create a branch: git checkout -b feature/xyz

    Commit your changes: git commit -m "Add amazing feature"

    Push: git push origin feature/xyz

    Open a Pull Request

---

Co-authored-by: Giovanni Rossi elek80s@users.noreply.github.com 

Co-authored-by: Luca lucaboca82@users.noreply.github.com

Co-authored-by: Bocaletto Luca bocaletto-luca@users.noreply.github.com 
