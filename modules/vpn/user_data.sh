#!/bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y ca-certificates wget curl net-tools gnupg

# ─── OpenVPN Access Server ────────────────────────────────────────────────────

mkdir -p /etc/apt/keyrings
wget -qO /etc/apt/keyrings/as-repo-public.asc \
  https://as-repository.openvpn.net/as-repo-public.asc

echo "deb [signed-by=/etc/apt/keyrings/as-repo-public.asc arch=amd64] \
  http://as-repository.openvpn.net/as/debian jammy main" \
  > /etc/apt/sources.list.d/openvpn-as-repo.list

apt-get update -y
apt-get install -y openvpn-as

# Wait for OpenVPN AS to fully start
sleep 15

# Fetch public IP using IMDSv2 (http_tokens = "required" is enforced on this instance)
IMDS_TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
PUBLIC_IP=$(curl -s -H "X-aws-ec2-metadata-token: $IMDS_TOKEN" \
  http://169.254.169.254/latest/meta-data/public-ipv4)

/usr/local/openvpn_as/scripts/sacli \
  --key "host.name" \
  --value "$PUBLIC_IP" \
  ConfigPut

# Do NOT reroute all client traffic through VPN — only route to private networks
/usr/local/openvpn_as/scripts/sacli \
  --key "vpn.client.routing.reroute_gw" \
  --value "false" \
  ConfigPut

# Route VPN clients to the VPN client subnet
/usr/local/openvpn_as/scripts/sacli \
  --key "vpn.server.routing.private_network.0" \
  --value "${vpn_client_cidr}" \
  ConfigPut

/usr/local/openvpn_as/scripts/sacli Start

# IMPORTANT: Change this default password immediately after first login
echo "openvpn:ChangeMe123!" | chpasswd

echo "OpenVPN AS setup complete for ${project_name}-${environment}" >> /var/log/user-data.log
echo "Admin UI: https://$PUBLIC_IP:943/admin" >> /var/log/user-data.log
echo "Client portal: https://$PUBLIC_IP/" >> /var/log/user-data.log
