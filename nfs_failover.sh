#!/bin/bash
#/opt/scripts/nfs_failover.sh

MOUNT_POINT="/mnt/nfs"
ACTIVE_NFS="nfs-server-1:/data"
PASSIVE_NFS="nfs-server-2:/data"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> /var/log/nfs_failover.log
}

CURRENT_NFS=$(mount | grep "$MOUNT_POINT" | awk '{print $1}')
ping -c 1 -W 2 "$(echo "$ACTIVE_NFS" | cut -d: -f1)" > /dev/null 2>&1
PING_RESULT=$?

if [ $PING_RESULT -eq 0 ]; then
  if [ "$CURRENT_NFS" != "$ACTIVE_NFS" ]; then
    log "Aktif NFS erişilebilir. Mount ediliyor: $ACTIVE_NFS"
    umount -f "$MOUNT_POINT" 2>/dev/null
    mount -t nfs "$ACTIVE_NFS" "$MOUNT_POINT" && log "Mount başarılı: $ACTIVE_NFS"
  fi
else
  if [ "$CURRENT_NFS" != "$PASSIVE_NFS" ]; then
    log "Aktif NFS erişilemiyor. Pasif mount ediliyor: $PASSIVE_NFS"
    umount -f "$MOUNT_POINT" 2>/dev/null
    mount -t nfs "$PASSIVE_NFS" "$MOUNT_POINT" && log "Mount başarılı: $PASSIVE_NFS"
  fi
fi
