# Kinetica

## Setup and benchmark

1. Deploy a c6a.4xlarge with 500 GB gp2 disk; `benchmark.sh` assumes that you are deploying an Ubuntu OS variant and runs the `setup-dev-ubuntu.sh` script. If you deploy any other OS, then you will need to install docker, java, and ripgrep separately.

2. Once you have the VM up and running, you can run the `benchmark.sh` script for a one-click install and run; it will:

-- download and install the `Kinetica` developer edition and its sql-client `kisql`

-- increase the RAM tier (via `alter tier`) - please adjust this value if needed

-- ingest the dataset

-- run the queries

All the queries will be executed on behalf of the user `admin` with the password `admin`.

```bash
./benchmark.sh
```

## Notes - out of the box, you will see output like so

Digest: sha256:6efe2c092552776fb87f24a8b41506ef427e0e8dce72889540f071b364f416e6

Status: Downloaded newer image for kinetica/kinetica-cpu:7.2.3.8.20260214171705.ga

b92f09b249308bd8ec120bdb8f9a0a984a525a2c94deec57e03a630b171b5a48

Alter password : Using environment variable KINETICA_ADMIN_PASSWORD

Success : Password for user admin has been updated and Kinetica is stopped.

Install : Ok

Starting : Ok

Start : Ok

...
...
...

Rows affected: 1

Timing (seconds): Connection=0.814, Query=0.181

Rows affected: 1

Timing (seconds): Connection=0.808, Query=0.209
...
...
...

Data size: 265563152 total

[0.562, 0.374, 0.276],

[0.405, 0.321, 0.251],

[0.395, 0.347, 0.264],

[0.502, 0.419, 0.360],

[0.399, 0.328, 0.244],

[0.480, 0.481, 0.581],

[0.433, 0.327, 0.253],

[0.582, 0.481, 0.348],

[0.376, 0.331, 0.263],

[0.562, 0.548, 0.407],

[0.438, 0.350, 0.282],

[0.430, 0.339, 0.314],

[0.359, 0.285, 0.301],

[0.360, 0.272, 0.292],

[0.766, 0.736, 0.709],

[0.371, 0.272, 0.275],

[0.420, 0.305, 0.286],
