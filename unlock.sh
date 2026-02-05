#!/bin/bash
set -e

echo "[*] Checking sshd service..."
if ! command -v sshd >/dev/null; then
  echo "[!] SSH server not installed. Installing..."
  apt update && apt install -y openssh-server
fi

echo "[*] Ensuring sshd is enabled..."
systemctl enable ssh || systemctl enable sshd || true

echo "[*] Checking sshd_config..."
SSHD_CONFIG="/etc/ssh/sshd_config"

# Ensure it's not blocking connections
sed -i 's/^#\?Port .*/Port 22/' "$SSHD_CONFIG"
sed -i 's/^#\?ListenAddress .*/ListenAddress 0.0.0.0/' "$SSHD_CONFIG"
sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin yes/' "$SSHD_CONFIG"
sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication yes/' "$SSHD_CONFIG"

echo "[*] Restarting SSH service..."
systemctl restart ssh || systemctl restart sshd

echo "[*] Checking SSH is listening..."
ss -lntp | grep ':22' || echo "[!] Port 22 not listening!"

echo "[*] Checking /etc/hosts.deny..."
if grep -q "sshd" /etc/hosts.deny 2>/dev/null; then
  echo "[!] Removing sshd from /etc/hosts.deny"
  sed -i '/sshd/d' /etc/hosts.deny
fi

echo "[*] Flushing all iptables rules..."
iptables -F
iptables -X
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

echo "[*] Disabling nftables rules if any..."
if command -v nft >/dev/null; then
  nft flush ruleset || true
fi

echo "[*] Verifying SSH port open in firewall..."
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

echo "[*] Done."
ss -lntp | grep ':22' || echo "[!] SSH still not listening on port 22"

echo "[*] If you're still locked out, check cloud firewall / provider panel"
