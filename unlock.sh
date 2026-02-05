#!/bin/bash
set -e

echo "[*] Flushing iptables rules..."
iptables -F
iptables -X
iptables -t nat -F
iptables -t mangle -F

echo "[*] Resetting default policies..."
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

echo "[*] Verifying..."
iptables -L -n

echo "[✓] SSH UNLOCKED. You can connect now."
