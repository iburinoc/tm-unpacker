#!/bin/bash

set -euxo pipefail
#set +e

uid=${UID:-0}
gid=${GID:-0}

function cleanup() {
    set +e
    sleep .1
    umount /bind
    umount /tm
    umount /hfs
    umount /image
}
trap cleanup EXIT

sparsebundlefs -oallow_other /sparsebundle /image

result="$(parted -s /image/sparsebundle.dmg unit B print 2>/dev/null \
    | grep hfsx \
    | awk '{print $2 " " $4}' | tr -d B)"

offset=$(echo $result | cut -f 1 -d ' ')
size=$(echo $result | cut -f 2 -d ' ')

mount -t hfsplus -oro,loop,offset=$offset,sizelimit=$size /image/sparsebundle.dmg /hfs
tmfs /hfs /tm -oallow_other
bindfs /tm /bind -u $uid -g $gid

"$@"
