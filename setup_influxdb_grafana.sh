#!/bin/bash

# Update package lists
echo "Updating package lists..."
sudo apt-get update

# Install InfluxDB
echo "Installing InfluxDB..."
wget -qO- https://repos.influxdata.com/influxdb.key | sudo apt-key add -
source /etc/os-release
echo "deb https://repos.influxdata.com/${ID} ${VERSION_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/influxdb.list
sudo apt-get update
sudo apt-get install -y influxdb

# Start and enable InfluxDB
echo "Starting and enabling InfluxDB..."
sudo systemctl start influxdb
sudo systemctl enable influxdb

# Install InfluxDB client
echo "Installing InfluxDB client..."
sudo apt-get install -y influxdb-client

# Install Grafana
echo "Installing Grafana..."
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee /etc/apt/sources.list.d/grafana.list
sudo apt-get update
sudo apt-get install -y grafana

# Start and enable Grafana
echo "Starting and enabling Grafana..."
sudo systemctl start grafana-server
sudo systemctl enable grafana-server

# Wait for Grafana to start
sleep 10

# Create InfluxDB database for njmon
echo "Creating InfluxDB database for njmon..."
influx -execute 'CREATE DATABASE njmon'

# Configure Grafana data source
echo "Configuring Grafana data source..."
GRAFANA_API_URL="http://localhost:3000/api/datasources"
GRAFANA_USER="admin"
GRAFANA_PASSWORD="admin"

# Wait for Grafana to be ready
until curl -s --user ${GRAFANA_USER}:${GRAFANA_PASSWORD} ${GRAFANA_API_URL}; do
  echo "Waiting for Grafana to be ready..."
  sleep 5
done

# Add InfluxDB data source to Grafana
curl -s --user ${GRAFANA_USER}:${GRAFANA_PASSWORD} -X POST ${GRAFANA_API_URL} -H "Content-Type: application/json" -d '{
  "name": "InfluxDB",
  "type": "influxdb",
  "access": "proxy",
  "url": "http://localhost:8086",
  "database": "njmon",
  "user": "",
  "password": "",
  "isDefault": true
}'

echo "InfluxDB and Grafana setup complete."
echo "Visit http://localhost:3000 to access Grafana. Default login is admin/admin."
