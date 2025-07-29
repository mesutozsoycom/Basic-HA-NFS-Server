Script dosyasını oluştur: /opt/scripts/nfs_failover.sh

Bu script’e çalıştırma yetkisi ver: chmod +x /opt/scripts/nfs_failover.sh

systemd servis dosyası oluştur:
/etc/systemd/system/nfs-failover.service

Timer dosyası oluştur:
/etc/systemd/system/nfs-failover.timer

Timer’ı etkinleştir ve başlat:

# systemd daemon'u yeniden yükle
sudo systemctl daemon-reexec
sudo systemctl daemon-reload

# timer'ı etkinleştir
sudo systemctl enable --now nfs-failover.timer

# Durum kontrolü
systemctl list-timers --all | grep nfs-failover

Loglar: journalctl -u nfs-failover.service veya /var/log/nfs_failover.log 

