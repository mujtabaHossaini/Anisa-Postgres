FROM apache/airflow:2.8.1-python3.11

USER root

# Handle issues with repository updates
RUN set -eux; \
    echo "Acquire::Check-Valid-Until \"false\";" > /etc/apt/apt.conf.d/ignore-release-valid-until; \
    apt-get update || true; \
    rm -rf /etc/apt/apt.conf.d/ignore-release-valid-until

RUN apt-get install -y --no-install-recommends \
         build-essential \
         postgresql-client \
    && apt-get autoremove -yqq --purge \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

USER airflow

# Install Python packages required for your DAGs
RUN pip install --no-cache-dir pendulum==2.1.2 pytz==2023.3.post1 python-dateutil==2.8.2 python-dotenv==1.0.1

# Set environment variables from the .env file
ENV REDIS_HOST=${REDIS_HOST}
ENV REDIS_PASSWORD=${REDIS_PASSWORD}
