# A guide to install and configure a home media server
The following guide covers the main steps needed to setup a home media center on Ubuntu 20.04. Most of these steps will work on other Ubuntu versions (but haven't been tested).

The below isn't a rocket science obviously — I started it for my own sanity (to document what I've done and make it repeatable) but others might find it useful as well :)

The end result is a headless Ubuntu Server 20.04 with QEMU/KVM hypervisor, Docker, ZFS and an admin web UI to manage all of this.

## 1. Initial setup

### Upload ssh keys from the client machine
```
ssh-copy-id <user>@<server-ip-address>
```

### Run updates
```
sudo apt update && sudo apt upgrade
```

### Change hostname if needed
```
sudo hostnamectl set-hostname <hostname>
```

### (Optionally) disable IPv6 
Edit `/etc/default/grub` and add `ipv6.disable=1` to the following variables:
```
GRUB_CMDLINE_LINUX_DEFAULT
GRUB_CMDLINE_LINUX
```
Then, to apply changes run:
```
sudo update-grub
```

### Mount external drives as needed
```
sudo mkdir /media/<folder-name>
sudo mount /dev/<device-name> /media/<folder-name>
```

### Copy files as needed
```
rsync -a --progress --stats --human-readable <source> <destination>
```

### Configure software sources
Edit `/etc/apt/sources.list` as needed

### Configure unattended upgrades
Edit `/etc/apt/apt.conf.d/50unattended-upgrades` as needed.

### Install a few essential packages
```
sudo apt install htop mc python3-pip zfsutils-linux samba cockpit cockpit-machines
pip3 install archey4
```

### (Optionally) get rid of Snap
```
sudo snap remove package-name
sudo systemctl stop snapd && sudo systemctl disable snapd
sudo apt purge snapd
rm -rf ~/snap
sudo rm -rf /snap /var/snap /var/lib/snapd /var/cache/snapd /usr/lib/snapd
```

### Add new user and group for container file permissions
```
sudo useradd -r media
sudo usermod -a -G media media
```

### (Optionally) add your user to kvm group for easier VM management
```
usermod -a -G kvm <username>
```

### (Optionally) install GUI (better to do it in one of the VMs rather than the host)
```
sudo apt install lubuntu-desktop --no-install-recommends
```

### (Optionally) enable autologin 
Add the following to `/etc/sddm.conf`
```
[Autologin]
Session=Lubuntu
User=<username>
```

### (Optionally) install RealVNC 
Download .deb package from here: https://www.realvnc.com/en/connect/download/vnc/linux/) and run
```
dpkg -i <VNC-Server>.deb
systemctl start vncserver-x11-serviced.service
systemctl enable vncserver-x11-serviced.service
```
From the GUI session run this and enter credentials:
```
sudo vnclicensewiz
```

## 2. Preparing disks for zfs

### Add disk aliases 
Check `/dev/disk/by-id/` folder to identify your disks and add corresponding aliases to `/etc/zfs/vdev_id.conf`:
```
alias hdd1 /dev/disk/by-id/wwn-0x5000cca295e0817e
alias hdd2 /dev/disk/by-id/wwn-0x5000cca2a1ccc897
alias hdd3 /dev/disk/by-id/wwn-0x5000cca295e21818
alias hdd4 /dev/disk/by-id/wwn-0x5000cca2afe413a1

alias ssd1 /dev/disk/by-id/
alias ssd2 /dev/disk/by-id/

alias ssdz /dev/disk/by-id/
```

### To apply the changes run;
```
sudo udevadm trigger
```

### Create zfs pool
```
sudo zpool create -f -o ashift=12 -m /mnt/hdd-zpool hdd-pool mirror hdd1 hdd2 mirror hdd3 hdd4
```

### Turn off writing access time — should help with performance
```
sudo zfs set atime=off hdd-pool
```

### Create data set
```
zfs create <nameofzpool>/<nameofdataset>
```

## 3. Optional tweaks

### Disable motd news
Edit `/etc/default/motd-new` as needed

### Disable motd help text 
Edit `/etc/update-motd.d/10-help-text` as needed

### If using cockpit, enable updates
Edit `/etc/netplan/00-installer-config.yaml` and add to the network section:
```
renderer: NetworkManager
```

## 4. Install and setup Docker

### Add repos, keys and install packages
```
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt install docker-ce
pip install docker-compose
```

### Add user to docker group
```
sudo usermod -aG docker ${USER}
```

### Move docker data directory by creating /etc/docker/daemon.json and adding:
```
{
"data-root": "/mnt/data/container-data/docker"
}
```

### (Optionally) install docker plugin for cockpit (deprecated by RedHat by still works)
```
wget https://launchpad.net/ubuntu/+source/cockpit/215-1~ubuntu19.10.1/+build/18889196/+files/cockpit-docker_215-1~ubuntu19.10.1_all.deb
sudo dpkg -i cockpit-docker_215-1~ubuntu19.10.1_all.deb
```

## 5. (Alternatively) install and setup Podman

### Add repos, keys and install packages
```
source /etc/os-release
sudo sh -c "echo 'deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${VERSION_ID}/ /' > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list"
wget -nv https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/xUbuntu_${VERSION_ID}/Release.key -O- | sudo apt-key add -
sudo apt update && sudo apt install podman
pip3 install podman-compose
```

### Change unprivileged ports - add to /etc/sysctl.conf
```
net.ipv4.ip_unprivileged_port_start=80
```

### Change container storage location
Edit `/etc/containers/storage.conf` and change the following values:
```
graphroot = "/mnt/data/container-data/containers/storage"
rootless_storage_path = "/mnt/data/container-data/containers-rootless/storage"
```

## 6. Setting up samba

### Add new system users as needed
```
sudo useradd -r <username>
```

### Create password for each samba user
```
sudo smbpasswd -a <username>
```

### Add samba user mapping 
Add the following config to `/etc/samba/smbusers`:
```
<linux-username> = <Samba-User-1>
<linux-username> = <Samba-User-2>
```

### Add samba shares:
Add the following settings to `/etc/samba/smb.conf`
```
[global]
   min protocol = SMB2
   protocol = SMB3
   username map = /etc/samba/smbusers
   veto files = /Thumbs.db/.DS_Store/._.DS_Store/.apdisk/
   delete veto files = yes
   vfs objects = fruit streams_xattr
   fruit:metadata = stream
   fruit:model = MacSamba
   fruit:posix_rename = yes
   fruit:veto_appledouble = no
   fruit:wipe_intentionally_left_blank_rfork = yes
   fruit:delete_empty_adfiles = yes
   use sendfile = true

[Share-name]
   comment = Share description
   path =
   writeable = yes
   browseable = yes
   valid users = optimus, bumblebee
   hide unreadable = yes
#  hide files = /.*/
   veto files = /.*/
   create mask = 0664
   force create mode = 0664
   create directory mask = 0774
   force directory mode = 0774
   vfs objects = fruit streams_xattr

#[Share-name-guest]
#   comment = Guest access to...
#   path =
#   writeable = No
#   browseable = yes
#   guest ok = yes
#   hide unreadable = yes
#   hide files = /Documents/ /Photos/ /Home*/ /.*/
#   veto files = /Documents/ /Photos/ /Home*/ /.*/
#   vfs objects = fruit streams_xattr
```