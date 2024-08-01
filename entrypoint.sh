#!/bin/bash

# Function to start Spark Master
start_master() {
    $SPARK_HOME/sbin/start-master.sh --port $SPARK_MASTER_PORT --webui-port $SPARK_MASTER_WEBUI_PORT
    tail -f /dev/null
}

# Function to start Spark Worker
start_worker() {
    $SPARK_HOME/sbin/start-worker.sh --cores $SPARK_WORKER_CORES --memory $SPARK_WORKER_MEMORY $SPARK_MASTER_URL
    tail -f /dev/null
}

# Function to start Spark History Server
start_history_server() {
    $SPARK_HOME/sbin/start-history-server.sh
    tail -f /dev/null
}

# Function to run Spark in client mode
run_client() {
    $SPARK_HOME/bin/spark-submit $SPARK_SUBMIT_ARGS
}

# Check SPARK_MODE environment variable
case "$SPARK_MODE" in
  master)
    start_master
    ;;
  worker)
    start_worker
    ;;
  client)
    run_client
    ;;
  history-server)
    start_history_server
    ;;
  *)
    echo "Invalid SPARK_MODE: $SPARK_MODE. Must be 'master', 'worker', or 'client' or 'history-server'"
    exit 1
    ;;
esac
