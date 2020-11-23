#!/usr/bin/env bash

set   -o errexit
set   -o errtrace
set   -o pipefail
shopt -s nullglob
IFS=$'\n\t'

rm -f /etc/machine-id
touch /etc/machine-id

cat > "/etc/sysconfig/network" << END
NETWORKING=yes
NOZEROCONF=yes
END

cat > "/etc/sysconfig/network-scripts/ifcfg-eth0"  << END
DEVICE=eth0
ONBOOT=yes
BOOTPROTO=dhcp
END

cp /usr/share/zoneinfo/UTC "/etc/localtime" || true

echo 'ZONE="UTC"' > "/etc/sysconfig/clock"

# cat > "/etc/fstab" << END
# LABEL=root /         xfs    defaults,relatime  1 1
# tmpfs   /dev/shm  tmpfs   defaults           0 0
# devpts  /dev/pts  devpts  gid=5,mode=620     0 0
# sysfs   /sys      sysfs   defaults           0 0
# proc    /proc     proc    defaults           0 0
# END

cat > "/etc/default/grub" << END
GRUB_TIMEOUT=1
GRUB_DISTRIBUTOR="$(sed 's, release .*$,,g' /etc/system-release)"
GRUB_DEFAULT=saved
GRUB_DISABLE_SUBMENU=true
GRUB_TERMINAL="serial console"
GRUB_SERIAL_COMMAND="serial --speed=115200"
GRUB_CMDLINE_LINUX="console=tty0 crashkernel=auto console=ttyS0,115200 net.ifnames=0"
GRUB_DISABLE_RECOVERY="true"
END

echo 'RUN_FIRSTBOOT=NO' > "/etc/sysconfig/firstboot"

grub2-mkconfig -o /boot/grub2/grub.cfg

systemctl enable sshd.service
systemctl enable cloud-init.service
systemctl mask tmp.mount

cat > "/etc/cloud/cloud.cfg" << END
users:
 - default
disable_root: 1
ssh_pwauth:   0
mount_default_fields: [~, ~, 'auto', 'defaults,nofail', '0', '2']
resize_rootfs_tmp: /dev
ssh_svcname: sshd
ssh_deletekeys:   True
ssh_genkeytypes:  [ 'rsa', 'ecdsa', 'ed25519' ]
syslog_fix_perms: ~
cloud_init_modules:
 - migrator
 - bootcmd
 - write-files
 - growpart
 - resizefs
 - set_hostname
 - update_hostname
 - update_etc_hosts
 - rsyslog
 - users-groups
 - ssh
cloud_config_modules:
 - mounts
 - locale
 - set-passwords
 - yum-add-repo
 - package-update-upgrade-install
 - timezone
 - puppet
 - chef
 - salt-minion
 - mcollective
 - disable-ec2-metadata
 - runcmd
cloud_final_modules:
 - rightscale_userdata
 - scripts-per-once
 - scripts-per-boot
 - scripts-per-instance
 - scripts-user
 - ssh-authkey-fingerprints
 - keys-to-console
 - phone-home
 - final-message
 - power-state-change

system_info:
  default_user:
    name: ec2-user
    lock_passwd: true
    gecos: Cloud User
    groups: [wheel, adm, systemd-journal]
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    shell: /bin/bash
  distro: rhel
  paths:
    cloud_dir: /var/lib/cloud
    templates_dir: /etc/cloud/templates
  ssh_svcname: sshd
datasource_list: [ Ec2, None ]
datasource:
  Ec2:
    timeout: 50
    max_wait: 200
# vim:syntax=yaml
END

systemctl stop docker || true

yum clean all
rm -rf /var/cache/yum
truncate -c -s 0 "/var/log/yum.log"

rm -f "/etc/resolv.conf"
touch "/etc/resolv.conf"
rm -f /etc/ssh/ssh_host_*_key*
userdel -f -r centos || true
