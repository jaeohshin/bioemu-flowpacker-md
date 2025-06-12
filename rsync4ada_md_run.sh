#!/bin/bash

rsync -avz --progress --update --times -e "ssh"  \
    --exclude='*.pdb' --exclude='*.gro' --exclude='*.trr' --exclude='*.log' --exclude='*.xtc' \
    jaeohshin@ada.kias.re.kr:/store/jaeohshin/work/md_run/ \
    /data/work/md_run/

exit
