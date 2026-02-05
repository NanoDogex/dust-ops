#!/bin/bash
set -e

echo "[*] Mounting root (md126) and /data (md127)..."
mount /dev/md126 /mnt || { echo "[!] Failed to mount /dev/md126"; exit 1; }
mount /dev/md127 /mnt/data || echo "[!] /data not mounted (optional)"

echo "[*] Mounting virtual filesystems..."
mount --bind /dev /mnt/dev
mount --bind /proc /mnt/proc
mount --bind /sys /mnt/sys

echo "[*] Entering chroot..."
chroot /mnt /bin/bash <<'EOF'
echo "[*] Resetting sshd_config to allow root login and password auth..."
cat > /etc/ssh/sshd_config <<CONFIG
Port 22
ListenAddress 0.0.0.0
PermitRootLogin yes
PasswordAuthentication yes
UsePAM yes
Subsystem sftp /usr/lib/openssh/sftp-server
CONFIG

echo "[*] Enabling and restarting ssh service..."
systemctl enable ssh || systemctl enable sshd
systemctl restart ssh || systemctl restart sshd

echo "[*] Flushing iptables to ensure port 22 is open..."
iptables -F
iptables -X
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

echo "[*] Verifying SSH is listening..."
ss -lntp | grep ':22' && echo "[✓] Port 22 is now open."

echo "[*] SSH should now be accessible. Do NOT exit rescue until tested."
EOF

echo "[*] All done. You are still in rescue. Test SSH before rebooting."
