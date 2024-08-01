# Use an official Ubuntu as a parent image
FROM ubuntu:24.04

# Set environment variables to non-interactive for automated installs
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-utils \
    wget \
    curl \
    git \
    vim \
    build-essential \
    ca-certificates \
    checkinstall \
    libncursesw5-dev \
    libssl-dev \
    libsqlite3-dev \
    tk-dev \
    libgdbm-dev \
    libc6-dev \
    libbz2-dev \
    libffi-dev \
    libsnappy1v5 \
    libsnappy-dev \
    zlib1g-dev \
    nodejs \
    npm \
    rsync \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Python
RUN wget https://www.python.org/ftp/python/3.11.9/Python-3.11.9.tgz \
    && tar -xvzf Python-3.11.9.tgz \
    && cd Python-3.11.9 \
    && ./configure --enable-optimizations \
    && make altinstall \
    && /usr/local/bin/python3.11 -V \
    && ln -sf /usr/local/bin/python3.11 /usr/bin/python3.11 \
    && ln -sf /usr/local/bin/python3.11 /usr/bin/python3 \
    && cd .. \
    && rm -rf Python-3.11.9 \
    && rm Python-3.11.9.tgz

# Install pip using wget
RUN wget https://bootstrap.pypa.io/get-pip.py -O get-pip.py && \
    /usr/local/bin/python3.11 get-pip.py && \
    rm get-pip.py

# Add pip to PATH
RUN echo "export PATH=\$PATH:/root/.local/bin" >> /root/.bashrc

# Upgrade pip
RUN /usr/local/bin/python3.11 -m pip install --upgrade pip --verbose

# Install Jupyter
RUN /usr/local/bin/python3.11 -m pip install jupyter

# Use bash to source .bashrc and confirm installations
RUN bash -c "source /root/.bashrc && /usr/local/bin/python3.11 -m pip --version && jupyter --version"

# Install OpenJDK 
RUN wget https://aka.ms/download-jdk/microsoft-jdk-17.0.12-linux-x64.tar.gz \
    && tar -xvzf microsoft-jdk-17.0.12-linux-x64.tar.gz \
    && mv jdk-17.0.12+7 jdk-17.0.12 \
    && mv jdk-17.0.12 /usr/local/jdk-17.0.12 \
    && rm microsoft-jdk-17.0.12-linux-x64.tar.gz

# Set JAVA_HOME environment variable
ENV JAVA_HOME=/usr/local/jdk-17.0.12
ENV PATH=$JAVA_HOME/bin:$PATH

# Install Apache Spark
RUN wget https://archive.apache.org/dist/spark/spark-3.4.3/spark-3.4.3-bin-hadoop3.tgz \
    && tar -xvzf spark-3.4.3-bin-hadoop3.tgz \
    && mv spark-3.4.3-bin-hadoop3 /usr/local/spark \
    && rm spark-3.4.3-bin-hadoop3.tgz

# Set SPARK_HOME environment variable
ENV SPARK_HOME=/usr/local/spark
ENV CLASSPATH=/usr/local/spark/jars/*
ENV PATH=$SPARK_HOME/bin:$PATH

ENV SPARK_MODE=master
ENV SPARK_WORKER_CORES=2
ENV SPARK_WORKER_MEMORY=2g
ENV SPARK_MASTER_URL=spark://spark-master:7077
ENV SPARK_SUBMIT_ARGS=""
ENV SPARK_CONF_DIR=/usr/local/spark/conf
ENV SPARK_MASTER_PORT=7077
ENV SPARK_MASTER_WEBUI_PORT=8080

ENV SPARK_HISTORY_OPTS="$SPARK_HISTORY_OPTS -Dspark.history.fs.logDirectory=/opt/spark-events -Dspark.history.ui.port=18080"
ENV SPARK_SUBMIT_OPTS="--Dspark.driver.host=spark-driver"

# Set the working directory
WORKDIR /usr/local/spark

# Expose ports (4040 for Spark UI, 8080 for master, 7077 for worker)
EXPOSE 4040 8080 7077

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]

# Default command
CMD ["bash"]
