# Use an official Ubuntu as a parent image
FROM ubuntu:22.04

# Set environment variables to non-interactive for automated installs
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-utils \
    wget \
    curl \
    git \
    gnupg \
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
    lsb-release \
    zlib1g-dev \
    nodejs \
    npm \
    rsync \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Check if the Ubuntu version is supported using bash
RUN UBUNTU_VERSION=$(lsb_release -rs) && \
    bash -c 'if ! [[ "18.04 20.04 22.04 23.04 24.04" == *"${UBUNTU_VERSION}"* ]]; then \
    echo "Ubuntu ${UBUNTU_VERSION} is not currently supported."; \
    exit 1; \
    fi'

# Import the Microsoft GPG key and add the Microsoft SQL Server repository
RUN curl -sSL https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
    curl -sSL https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/prod.list | tee /etc/apt/sources.list.d/mssql-release.list

# Update the package list and install the required packages
RUN apt-get update && \
    ACCEPT_EULA=Y apt-get install -y msodbcsql17 && \
    ACCEPT_EULA=Y apt-get install -y mssql-tools && \
    echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> /root/.bashrc && \
    apt-get install -y unixodbc-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Source the .bashrc to update the PATH
RUN /bin/bash -c "source /root/.bashrc"

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

# Install Scala
RUN wget https://downloads.lightbend.com/scala/2.12.19/scala-2.12.19.tgz \
    && tar -xvzf scala-2.12.19.tgz \
    && mv scala-2.12.19 /usr/local/scala \
    && rm scala-2.12.19.tgz

# Set SCALA_HOME environment variable
ENV SCALA_HOME=/usr/local/scala
ENV PATH=$SCALA_HOME/bin:$PATH

# Install Apache Spark
RUN wget https://archive.apache.org/dist/spark/spark-3.4.3/spark-3.4.3-bin-hadoop3.tgz \
    && tar -xvzf spark-3.4.3-bin-hadoop3.tgz \
    && mv spark-3.4.3-bin-hadoop3 /usr/local/spark \
    && rm spark-3.4.3-bin-hadoop3.tgz

# COPY JAR files to the Spark jars directory
COPY drivers/* /usr/local/spark/jars/

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

ENV SPARK_HISTORY_OPTS="-Dspark.history.fs.logDirectory=/opt/spark-events -Dspark.history.ui.port=18080"
ENV SPARK_SUBMIT_OPTS="-Dspark.driver.host=spark-driver"

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
