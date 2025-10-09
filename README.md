# Apache PySpark Docker Image

This repository contains a Docker setup for running Apache Spark with PySpark. It includes configurations for running Spark in different modes: master, worker, client, and history-server.

## Prerequisites

- Docker installed on your machine.
- Internet connection to download necessary packages and dependencies.

## Setup

1. **Clone the repository**:

   ```bash
   git clone <repository-url>
   cd apache-pyspark-image
   ```

2. **Build the Docker image**:

   ```bash
   docker build -t apache-pyspark .
   ```

3. **Run the Docker container**:
   You can run the container in different modes by setting the `SPARK_MODE` environment variable in the `.env` file.

   - **Master mode**:

     ```bash
     docker run --env-file .env -p 8080:8080 -p 7077:7077 apache-pyspark
     ```

   - **Worker mode**:

     ```bash
     docker run --env-file .env -p 8081:8081 apache-pyspark
     ```

   - **Client mode**:

     ```bash
     docker run --env-file .env apache-pyspark
     ```

   - **History Server mode**:

     ```bash
     docker run --env-file .env -p 18080:18080 apache-pyspark
     ```

## Environment Variables

The following environment variables can be configured for the Docker setup:

```plaintext
# Base image version
UBUNTU_VERSION=22.04

# Python configuration
PYTHON_VERSION=3.14.0

# JDK configuration
JDK_VERSION=21.0.8

# Scala configuration
SCALA_VERSION=2.13.1

# Spark configuration
SPARK_VERSION=4.0.1
SPARK_MODE=master
SPARK_WORKER_CORES=2
SPARK_WORKER_MEMORY=2g
SPARK_MASTER_URL=spark://spark-master:7077
SPARK_SUBMIT_ARGS=""
SPARK_CONF_DIR=/usr/local/spark/conf
SPARK_MASTER_PORT=7077
SPARK_MASTER_WEBUI_PORT=8080
SPARK_HISTORY_OPTS="-Dspark.history.fs.logDirectory=/opt/spark-events -Dspark.history.ui.port=18080"
SPARK_SUBMIT_OPTS="-Dspark.driver.host=spark-driver"
```

You can set these environment variables in a `.env` file or pass them directly when running the Docker container.

## Notes

- Ensure that the ports specified in the `.env` file are available on your host machine.
- Modify the `.env` file as needed to suit your environment and requirements.

## License

This project is licensed under the MIT License.

## Running the Docker Container with Mounted Drivers

When running the Docker container, you can mount the directory containing your driver JAR files using the `-v` option. This allows you to manage the drivers outside of the Docker image.

### Example Command

```bash
docker run --env-file .env -p 8080:8080 -p 7077:7077 -v /path/to/your/drivers:/usr/local/spark/jars apache-pyspark
```

- Replace `/path/to/your/drivers` with the actual path on your host machine where the driver JAR files are located.
- The `-v` option maps the host directory to the container directory `/usr/local/spark/jars`, where Spark expects to find the JAR files.

### Benefits of Using Volumes

- **Flexibility**: You can update the drivers without rebuilding the Docker image.
- **Efficiency**: Reduces the size of the Docker image and speeds up the build process.
- **Convenience**: Easily switch between different sets of drivers by changing the host directory.

Ensure that the drivers are accessible and correctly mapped to the container for Spark to function properly.
