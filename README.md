############# A shell script to find out fast docker mirror and configure it for you automatically ###############
########################## Author: peyoot#hotmail .com ###########################################################
This script only have been tested and verified in Ubuntu 20.04 LTS
本脚本帮您查找和测试最快的dockerhub国内镜像, 在Ubuntu 20.04下测试通过。
用apt方式安装好docker后，下载脚本，然后：
sudo ./fast_mirror.sh

脚本会自动在docker的systemd系统服务中添加上测出的最快的镜像
###################################################################################

Before run the script please make sure you've install docker. If you haven't, just run "sudo apt install docker"

To set the fastest mirror for docker , simply run it as root:

sudo ./fast_mirror.sh 

The script then will try to pull a test image (registry:2) with the given mirror and set fastest mirror in /lib/systemd/system/docker.service

Good luck!!!
