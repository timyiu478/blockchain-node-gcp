resource "google_compute_network" "eth_vpc" {
  name                    = "ethereum-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "eth_subnet" {
  name          = "ethereum-subnet"
  network       = google_compute_network.eth_vpc.self_link
  region        = var.gcp_region
  ip_cidr_range = "10.0.0.0/24"
}

resource "google_compute_firewall" "eth_firewall" {
  name    = "ethereum-firewall"
  network = google_compute_network.eth_vpc.self_link

  allow {
    protocol = "tcp"
    ports    = ["22",  # SSH
                "443", # HTTPS
                "30303", "8545", "8551", "5052", "9000", # Ethereum ports
                "9090", "9091", "3000" # Prometheus and Grafana ports
               ]
  }

 allow {
    protocol = "udp"
    ports    = ["53"] # DNS
  }

  source_ranges = ["0.0.0.0/0"]  # Adjust as needed for security
}

resource "google_compute_instance" "eth_node" {
  name         = "ethereum-node"
  machine_type = var.eth_node_vm_machine_type
  zone         = var.gcp_region_zone

  boot_disk {
    initialize_params {
      image = "ubuntu-2204-jammy-v20250530"
      size  = 500
      type  = "pd-ssd"
    }
  }

  network_interface {
    # Attach to the VPC and subnetwork
    network = google_compute_network.eth_vpc.self_link
    subnetwork = google_compute_subnetwork.eth_subnet.self_link

    # Enable external IP for public access
    access_config {}
  }

  metadata = {
    eth_network = "hoodi"
  }

  metadata_startup_script = <<EOF
#!/bin/bash
sudo apt update && sudo apt install -y docker.io docker-compose
mkdir -p /ethereum-node # Ethereum node data directory
mkdir -p /prometheus /prometheus_data # Prometheus data directory
mkdir -p /grafana /grafana/provisioning # Grafana data directory

chmod -R 777 /prometheus_data # Ensure Prometheus has the right permissions

openssl rand -hex 32 > /ethereum-node/jwt.hex # Generate JWT secret for Nethermind and Lighthouse

cat > /prometheus/prometheus.yml <<EOD # Simplest Prometheus configuration file that scrapes metrics from Nethermind and Lighthouse
global:
  scrape_interval: 10s  # Adjust as needed

scrape_configs:
  - job_name: 'pushgateway' # Pushgateway for nethermind metrics
    honor_labels: true
    static_configs:
    - targets: ['pushgateway:9091']
  - job_name: 'lighthouse'
    static_configs:
      - targets: ['lighthouse:5064']  # Lighthouse metrics endpoint
EOD

cat > /grafana/grafana.ini <<EOD # Simplest Grafana configuration file that contains the essential settings
[server]
http_port = 3000
domain = 0.0.0.0

[security]
admin_user = admin
admin_password = admin

[database]
type = sqlite3
path = grafana.db
EOD

cat > docker-compose.yml <<EOD
version: '3.9'
networks:
  eth-network:
    driver: bridge
services:
  nethermind:
    image: nethermind/nethermind:latest
    container_name: nethermind-hoodi
    restart: unless-stopped
    networks:
      - eth-network
    volumes:
      - /ethereum-node/nethermind-data:/nethermind/data
      - /ethereum-node/jwt.hex:/nethermind/jwt.hex
    ports:
      - "30303:30303"  # P2P networking
      - "8545:8545"    # HTTP-RPC
      - "8551:8551"    # Engine API for consensus layer
      - "6060:6060"    # Metrics endpoint
    command: >
      --config hoodi
      --JsonRpc.Enabled true
      --JsonRpc.Host 0.0.0.0
      --JsonRpc.Port 8545
      --JsonRpc.EngineHost 0.0.0.0
      --JsonRpc.EnginePort 8551
      --JsonRpc.JwtSecretFile /nethermind/jwt.hex
      --metrics-enabled true
      --metrics-pushgatewayurl http://pushgateway:9091
  lighthouse:
    image: sigp/lighthouse:latest
    container_name: lighthouse-hoodi
    restart: unless-stopped
    networks:
      - eth-network
    volumes:
      - /ethereum-node/lighthouse-data:/root/.lighthouse
      - /ethereum-node/jwt.hex:/lighthouse/jwt.hex
    ports:
      - "9000:9000"  # P2P networking
      - "5052:5052"  # Beacon API
      - "5064:5064"  # Metrics
    command: >
      lighthouse bn
      --network hoodi
      --execution-endpoint http://nethermind:8551
      --checkpoint-sync-url https://hoodi.checkpoint.sigp.io
      --http
      --http-address 0.0.0.0
      --http-port 5052
      --execution-jwt /lighthouse/jwt.hex
      --metrics
  prometheus:
    image: prom/prometheus
    container_name: prometheus
    restart: unless-stopped
    volumes:
      - /prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - /prometheus_data:/prometheus
    command:
      - "--config.file=/etc/prometheus/prometheus.yml"
      - "--storage.tsdb.path=/prometheus"
    ports:
      - "9090:9090"
    networks:
      - eth-network
  pushgateway:
    image: prom/pushgateway
    container_name: pushgateway
    restart: unless-stopped
    ports:
      - "9091:9091"
    networks:
      - eth-network
  grafana:
    image: grafana/grafana
    container_name: grafana
    restart: unless-stopped
    ports:
      - "3000:3000"
    networks:
      - eth-network
    volumes:
      - /grafana/grafana.ini:/etc/grafana/grafana.ini
      - /grafana/provisioning/:/etc/grafana/provisioning/
EOD

docker-compose up -d
EOF
}

