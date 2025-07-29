#!/bin/bash

# flock kilit dosyası
LOCKFILE="/tmp/nfs_failover.lock"
exec 200>$LOCKFILE
flock -n 200 || exit 0  # Zaten çalışıyorsa çık

# Genel ayarlar
MOUNT_POINT="/mnt/nfs"
ACTIVE_NFS="nfs-server-1:/data"
PASSIVE_NFS="nfs-server-2:/data"
HEALTHCHECK_FILE="$MOUNT_POINT/.healthcheck"
LOG_FILE="/var/log/nfs_failover.log"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

is_mount_healthy() {
  mountpoint -q "$MOUNT_POINT" || return 1
  timeout 3 stat "$HEALTHCHECK_FILE" &>/dev/null || return 1
  return 0
}

mount_nfs() {
  local target_nfs="$1"
  umount -f "$MOUNT_POINT" &>/dev/null
  mkdir -p "$MOUNT_POINT"
  mount -t nfs "$target_nfs" "$MOUNT_POINT"
  if [ $? -eq 0 ]; then
    log "Mount başarılı: $target_nfs"
  else
    log "Mount başarısız: $target_nfs"
  fi
}

# Ana kontrol başlasın
CURRENT_NFS=$(mount | grep "$MOUNT_POINT" | awk '{print $1}')

# Eğer mount sağlıklıysa hiçbir şey yapma
if is_mount_healthy; then
  log "Mount sağlıklı: $CURRENT_NFS"
  exit 0
fi

log "Mevcut mount bozuk veya erişilemez. Failover başlatılıyor..."

# Aktif NFS mount etmeyi dene
mount_nfs "$ACTIVE_NFS"
if is_mount_healthy; then
  log "Aktif NFS başarıyla geri geldi."
  exit 0
fi

# Aktif başarısız → Pasif'e geç
log "Aktif başarısız. Pasif NFS deneniyor..."
mount_nfs "$PASSIVE_NFS"
if is_mount_healthy; then
  log "Pasif NFS başarıyla mount edildi."
  exit 0
else
  log "HATA: Hem aktif hem pasif NFS erişilemez durumda!"
  exit 1
fi
