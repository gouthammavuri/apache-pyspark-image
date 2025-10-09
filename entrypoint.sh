#!/bin/bash
# Validate critical environment variables
if [ -z "$SPARK_HOME" ] || [ -z "$SPARK_MODE" ]; then
    echo "SPARK_HOME and SPARK_MODE must be set"
    exit 1
fi

if [ "$SPARK_MODE" == "worker" ] && ([ -z "$SPARK_WORKER_CORES" ] || [ -z "$SPARK_WORKER_MEMORY" ] || [ -z "$SPARK_MASTER_URL" ]); then
    echo "SPARK_WORKER_CORES, SPARK_WORKER_MEMORY, and SPARK_MASTER_URL must be set for worker mode"
    exit 1
fi

if [ "$SPARK_MODE" == "master" ] && ([ -z "$SPARK_MASTER_PORT" ] || [ -z "$SPARK_MASTER_WEBUI_PORT" ]); then
    echo "SPARK_MASTER_PORT and SPARK_MASTER_WEBUI_PORT must be set for master mode"
    exit 1
fi

if [ "$SPARK_MODE" == "client" ] && [ -z "$SPARK_SUBMIT_ARGS" ]; then
    echo "SPARK_SUBMIT_ARGS must be set for client mode"
    exit 1
fi

# Function to start Spark Master
start_master() {
    echo "Starting Spark Master..."
    $SPARK_HOME/sbin/start-master.sh --port $SPARK_MASTER_PORT --webui-port $SPARK_MASTER_WEBUI_PORT
    if [ $? -ne 0 ]; then
        echo "Failed to start Spark Master"
        exit 1
    fi
    echo "Spark Master started successfully"
    tail -f /dev/null
}

# Function to start Spark Worker
start_worker() {
    echo "Starting Spark Worker..."
    $SPARK_HOME/sbin/start-worker.sh --cores $SPARK_WORKER_CORES --memory $SPARK_WORKER_MEMORY $SPARK_MASTER_URL
    if [ $? -ne 0 ]; then
        echo "Failed to start Spark Worker"
        exit 1
    fi
    echo "Spark Worker started successfully"
    tail -f /dev/null
}

# Function to start Spark History Server
start_history_server() {
    echo "Starting Spark History Server..."
    $SPARK_HOME/sbin/start-history-server.sh
    if [ $? -ne 0 ]; then
        echo "Failed to start Spark History Server"
        exit 1
    fi
    echo "Spark History Server started successfully"
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
    echo "Invalid SPARK_MODE: $SPARK_MODE. Must be 'master', 'worker', 'client', or 'history-server'"
    exit 1
    ;;
esac
