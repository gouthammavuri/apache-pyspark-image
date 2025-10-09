ARG UBUNTU_VERSION=22.04

# Use an official Ubuntu as a parent image
FROM ubuntu:${UBUNTU_VERSION}

# Set environment variables to non-interactive for automated installs
ENV DEBIAN_FRONTEND=noninteractive

# Sort package names alphanumerically
RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-utils \
    build-essential \
    ca-certificates \
    checkinstall \
    curl \
    git \
    gnupg \
    libc6-dev \
    libbz2-dev \
    libffi-dev \
    libgdbm-dev \
    libncursesw5-dev \
    libsnappy-dev \
    libsnappy1v5 \
    libsqlite3-dev \
    libssl-dev \
    lsb-release \
    nodejs \
    npm \
    rsync \
    tk-dev \
    vim \
    wget \
    zlib1g-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/* && \
    UBUNTU_VERSION=$(lsb_release -rs) && \
    bash -c 'if ! [[ "18.04 20.04 22.04 23.04 24.04" == *"${UBUNTU_VERSION}"* ]]; then \
    echo "Ubuntu ${UBUNTU_VERSION} is not currently supported."; \
    exit 1; \
    fi' && \
    curl -sSL https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
    curl -sSL https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/prod.list | tee /etc/apt/sources.list.d/mssql-release.list && \
    apt-get update && \
    ACCEPT_EULA=Y apt-get install -y msodbcsql18 && \
    ACCEPT_EULA=Y apt-get install -y mssql-tools && \
    echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> /root/.bashrc && \
    apt-get install -y unixodbc-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Source the .bashrc to update the PATH
RUN /bin/bash -c "source /root/.bashrc"

# Move ARG instructions closer to their usage
ARG PYTHON_VERSION=3.14.0
ADD https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz .
RUN tar -xvzf Python-${PYTHON_VERSION}.tgz \
    && cd Python-${PYTHON_VERSION} \
    && ./configure --enable-optimizations \
    && make altinstall \
    && /usr/local/bin/python3.14 -V \
    && ln -sf /usr/local/bin/python3.14 /usr/bin/python3.14 \
    && ln -sf /usr/local/bin/python3.14 /usr/bin/python3 \
    && cd .. \
    && rm -rf Python-${PYTHON_VERSION} \
    && rm Python-${PYTHON_VERSION}.tgz

ARG JDK_VERSION=21.0.8
ADD https://aka.ms/download-jdk/microsoft-jdk-${JDK_VERSION}-linux-x64.tar.gz .
RUN tar -xvzf microsoft-jdk-${JDK_VERSION}-linux-x64.tar.gz \
    && mv jdk-${JDK_VERSION}+9 jdk-${JDK_VERSION} \
    && mv jdk-${JDK_VERSION} /usr/local/jdk-${JDK_VERSION} \
    && rm microsoft-jdk-${JDK_VERSION}-linux-x64.tar.gz

ARG SCALA_VERSION=2.13.1
ADD https://downloads.lightbend.com/scala/${SCALA_VERSION}/scala-${SCALA_VERSION}.tgz .
RUN tar -xvzf scala-${SCALA_VERSION}.tgz \
    && mv scala-${SCALA_VERSION} /usr/local/scala \
    && rm scala-${SCALA_VERSION}.tgz

ARG SPARK_VERSION=4.0.1
ADD https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz .
RUN tar -xvzf spark-${SPARK_VERSION}-bin-hadoop3.tgz \
    && mv spark-${SPARK_VERSION}-bin-hadoop3 /usr/local/spark \
    && rm spark-${SPARK_VERSION}-bin-hadoop3.tgz

# Install pip using wget
RUN wget https://bootstrap.pypa.io/get-pip.py -O get-pip.py && \
    /usr/local/bin/python3.14 get-pip.py && \
    rm get-pip.py

# Add pip to PATH
RUN echo "export PATH=\$PATH:/root/.local/bin" >> /root/.bashrc

# Upgrade pip
RUN /usr/local/bin/python3.14 -m pip install --upgrade pip --verbose

# Install Jupyter
RUN /usr/local/bin/python3.14 -m pip install jupyter

# Use bash to source .bashrc and confirm installations
RUN bash -c "source /root/.bashrc && /usr/local/bin/python3.14 -m pip --version && jupyter --version"

# Install OpenJDK 
# Set JAVA_HOME environment variable
ENV JAVA_HOME=/usr/local/jdk-${JDK_VERSION}
ENV PATH=$JAVA_HOME/bin:$PATH

# Install Scala
# Set SCALA_HOME environment variable
ENV SCALA_HOME=/usr/local/scala
ENV PATH=$SCALA_HOME/bin:$PATH

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
