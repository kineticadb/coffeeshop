# Kinetica

A one-click benchmark suite for coffeeshop benchmark on [Kinetica](https://www.kinetica.com/) Developer Edition. It provisions the database, ingests a dataset, and runs a set of 17 timed SQL queries — all from a single script.

---

## Quick Start

On any Ubuntu VM or container with **500 GB** of available storage:

```bash
./benchmark.sh
```

That's it. The script handles everything described below.

---

## What the Script Does

`benchmark.sh` assumes an **Ubuntu-based** OS and calls `setup-dev-ubuntu.sh` to install prerequisites. If you're on a different OS, you'll need to install the following manually before running the benchmark:

- Docker
- Java
- ripgrep

Once prerequisites are in place, the script will:

1. **Download and install** the Kinetica Developer Edition and its SQL client (`kisql`).
2. **Increase the RAM tier** (via `ALTER TIER`) — adjust this value in the script if your VM has more or less memory.
3. **Ingest the dataset** into the database.
4. **Run the benchmark queries** and report timings.

> All queries run as user `admin` with password `admin`.

---

## Understanding the Output

A typical run prints several stages of output. Here's what to expect.

### 1. Installation and Startup

```
Digest: sha256:6efe2c09...
Status: Downloaded newer image for kinetica/kinetica-cpu:7.2.3.8.20260214171705.ga
b92f09b249...

Alter password : Using environment variable KINETICA_ADMIN_PASSWORD
Success         : Password for user admin has been updated and Kinetica is stopped.
Install         : Ok
Starting        : Ok
Start           : Ok
```

This confirms that the Docker image was pulled, the admin password was set, and Kinetica started successfully.

### 2. Data Ingestion

```
Rows affected: 1
Timing (seconds): Connection=0.814, Query=0.181

Rows affected: 1
Timing (seconds): Connection=0.808, Query=0.209
```

Each line pair represents one batch or statement in the ingestion phase, showing the connection overhead and the time the query itself took.

### 3. Benchmark Results

```
Data size: 265563152 total

[0.562, 0.374, 0.276],
[0.405, 0.321, 0.251],
[0.395, 0.347, 0.264],
...
```

The final block is the core benchmark output. It reports the **total data size** (in bytes) followed by a table of query timings.

Each row corresponds to **one benchmark query** (Query 1, Query 2, …), and each column is a **successive execution** of that same query:

| Column | Meaning |
|--------|---------|
| 1st value | **Run 1** — cold or near-cold execution |
| 2nd value | **Run 2** — benefits from warmed caches |
| 3rd value | **Run 3** — typically the fastest, fully warmed |

All values are in **seconds**.

For example:

```
[0.562, 0.374, 0.276]   ← Query 1:  Run 1 = 0.562 s, Run 2 = 0.374 s, Run 3 = 0.276 s
[0.405, 0.321, 0.251]   ← Query 2:  Run 1 = 0.405 s, Run 2 = 0.321 s, Run 3 = 0.251 s
```

> **Tip:** The drop from Run 1 to Run 3 shows how much Kinetica's caching and query optimizations improve repeated query performance. A smaller drop means the query was already well-optimized on the first pass.

### Results File

After the benchmark completes, a `result.csv` file is written to the current working directory containing the full set of query timings. You can use this file for further analysis, charting, or comparison across runs.

---

## Customization

- **RAM tier** — Edit the `ALTER TIER` value inside `benchmark.sh` to match your VM's available memory.
- **Dataset** - Coffeeshop benchmark has different size datasets. The provided scipts loads approximately 720 million rows in the fact table.
