# Ubuntu with Apache Spark

## Overview

This Docker image is based on the official Ubuntu 24.04 image and comes pre-configured with Python 3.11, Apache Spark 3.4.3, Scala 2.12.19 and Java jdk 17. It is designed to provide a robust development environment for data science and big data processing.

## Features

- **Ubuntu 24.04**: The base operating system.
- **Python 3.11.9**: The latest version of Python for development.
- **Scala 2.12.19: Scala Version
- **Apache Spark 3.4.3**: A powerful engine for big data processing.
- **OpenJDK 17**: Required for running Apache Spark.

## Usage

### Running the Container

To run the container, use the following command:

```sh
docker run -p 8888:8888 -v /scripts:/home/gmavuri/work gouthammavuri/spark
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
