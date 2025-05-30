#!/bin/sh

# Replace this with your EC2 public IP or domain
HOST="44.204.5.96"

SERVICES="api-gateway user-service crime-service location-service discovery-server"
PORTS="8080 8081 8082 8083 8761"

echo "=============================="
echo "🔍 Actuator Health Checks"
echo "=============================="

i=1
for service in $SERVICES; do
  port=$(echo $PORTS | cut -d' ' -f$i)
  url="http://${HOST}:${port}/actuator/health"
  echo ""
  echo "👉 Checking $service on $url"
  curl --silent --show-error --fail "$url" || echo "❌ $service is not responding!"
  i=$((i + 1))
done

echo ""
echo "✅ Done checking services."
