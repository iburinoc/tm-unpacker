#!/bin/bash

set -euxo pipefail
#set +e

uid=${UID:-0}
gid=${GID:-0}

loop=${LOOP:-999}
loopback=/dev/loop$loop

function cleanup() {
    set +e
    umount /bind
    umount /tm
    umount /hfs
    losetup -d $loopback
    rm $loopback
    umount /image
}
trap cleanup EXIT

sparsebundlefs -oallow_other /sparsebundle /image

result="$(parted -s /image/sparsebundle.dmg unit B print 2>/dev/null \
    | grep hfsx \
    | awk '{print $2 " " $4}' | tr -d B)"

strt=$(echo $result | cut -f 1 -d ' ')
size=$(echo $result | cut -f 2 -d ' ')

mknod -m 0660 $loopback b 7 $loop
losetup -r -o $strt $loopback /image/sparsebundle.dmg

#mount -t hfsplus -o ro $loopback /hfs
#tmfs /hfs /tm -oallow_other
#bindfs /tm /bind -u $uid -g $gid

"$@"
