####################### A shell script to find out fast docker mirror and configure it for you automatically ############################
######################################## Author: peyoot#hotmail .com ####################################################################
This script only tested and verified in Ubuntu 20.04 LTS

Before run the script please make sure you've install docker. If you haven't, just run "sudo apt install docker"

To set the fastest mirror for docker , simply run it as root:

sudo ./fast_mirror.sh 

The script then will try to pull a test image (registry:2) with the given mirror and set fastest mirror in /lib/systemd/system/docker.service

Good luck!!!
