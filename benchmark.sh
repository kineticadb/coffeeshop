#!/usr/bin/bash

# Run setup.sh (assume we are running on ubuntu)
./setup-dev-ubuntu.sh

# download the db
export KINETICA_ADMIN_PASSWORD=admin
curl https://files.kinetica.com/install/kinetica.sh -o kinetica && chmod u+x kinetica && sudo -E ./kinetica start

# set up the cli
wget --continue --progress=dot:giga https://github.com/kineticadb/kisql/raw/v7.1.7.2/kisql

chmod u+x ./kisql

export KI_PWD="admin"
CLI="./kisql --host localhost --user admin"

# create schema and tune RAM tier
$CLI --sql "CREATE SCHEMA IF NOT EXISTS coffeeshop;"
$CLI --sql "ALTER TIER ram WITH OPTIONS ('capacity' = '32000000000');"

# create data source
$CLI --sql "CREATE or replace DATA SOURCE coffee_bench_ds LOCATION = 'S3' WITH OPTIONS (BUCKET NAME = 'doris-regression', REGION = 'us-east-1');"

START=$(date +%s)

# create and load dim_products
$CLI --sql "CREATE REPLICATED TABLE \"coffeeshop\".\"dim_products\" (\"record_id\" TINYINT NOT NULL, \"product_id\" TINYINT NOT NULL, \"name\" VARCHAR (32, dict) NOT NULL, \"category\" VARCHAR (8, dict) NOT NULL, \"subcategory\" VARCHAR (8, dict) NOT NULL, \"standard_cost\" REAL NOT NULL, \"standard_price\" REAL NOT NULL, \"from_date\" DATE (dict) NOT NULL, \"to_date\" DATE (dict) NOT NULL) TIER STRATEGY (( ( VRAM 1, RAM 5, DISK0 5, PERSIST 5 ) ));"

$CLI --sql "LOAD DATA INTO coffeeshop.dim_products FROM FILE PATHS 'coffee_bench/dim_products/' FORMAT PARQUET WITH OPTIONS (ON ERROR = PERMISSIVE, DATA SOURCE = 'coffee_bench_ds', BAD RECORD TABLE = 'coffeeshop.XX_dim_products');"

# create and load dim_locations
$CLI --sql "CREATE REPLICATED TABLE \"coffeeshop\".\"dim_locations\" (\"record_id\" SMALLINT NOT NULL, \"location_id\" VARCHAR (8, dict, primary_key) NOT NULL, \"city\" VARCHAR (16, dict) NOT NULL, \"state\" VARCHAR (2, dict) NOT NULL, \"country\" VARCHAR (4, dict) NOT NULL, \"region\" VARCHAR (16, dict) NOT NULL) TIER STRATEGY (( ( VRAM 1, RAM 5, DISK0 5, PERSIST 5 ) ));"

$CLI --sql "LOAD DATA INTO coffeeshop.dim_locations FROM FILE PATHS 'coffee_bench/dim_locations/' FORMAT PARQUET WITH OPTIONS (ON ERROR = PERMISSIVE, DATA SOURCE = 'coffee_bench_ds', BAD RECORD TABLE = 'coffeeshop.XX_dim_locations');"

# create and load fact_sales
$CLI --sql "CREATE TABLE \"coffeeshop\".\"fact_sales\" (\"order_id\" VARCHAR (64) NOT NULL, \"order_line_id\" VARCHAR NOT NULL, \"order_date\" DATE (dict, shard_key) NOT NULL, \"time_of_day\" VARCHAR (16, dict) NOT NULL, \"season\" VARCHAR (8, dict) NOT NULL, \"month\" TINYINT NOT NULL, \"location_id\" VARCHAR (8, dict, shard_key) NOT NULL, \"region\" VARCHAR (16, dict) NOT NULL, \"product_name\" VARCHAR (32, dict, shard_key) NOT NULL, \"quantity\" TINYINT NOT NULL, \"sales_amount\" REAL NOT NULL, \"discount_percentage\" TINYINT NOT NULL, \"product_id\" TINYINT NOT NULL) PARTITION BY LIST (YEAR(order_date), MONTH(order_date)) AUTOMATIC TIER STRATEGY (( ( VRAM 1, RAM 5, DISK0 5, PERSIST 5 ) ));"

$CLI --sql "LOAD DATA INTO coffeeshop.fact_sales FROM FILE PATHS 'coffee_bench/fact_sales_500m/' FORMAT PARQUET WITH OPTIONS (ON ERROR = PERMISSIVE, DATA SOURCE = 'coffee_bench_ds', BAD RECORD TABLE = 'coffeeshop.XX_fact_sales_500m');"

END=$(date +%s)
LOADTIME=$(echo "$END - $START" | bc)
echo "Load time: $LOADTIME"
echo "Data size: $(du -bcs ./kinetica-persist/gpudb | grep total)"

# run the queries
./run.sh
