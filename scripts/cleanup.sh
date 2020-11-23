#!/bin/sh -eux

# should output one of 'redhat' 'centos' 'oraclelinux'
distro="`rpm -qf --queryformat '%{NAME}' /etc/redhat-release | cut -f 1 -d '-'`"

# systemd should generate a new machine id during the first boot, to
# avoid having multiple Vagrant instances with the same id in the local
# network. /etc/machine-id should be empty, but it must exist to prevent
# boot errors (e.g.  systemd-journald failing to start).
:>/etc/machine-id

# Remove development and kernel source packages
yum -y remove gcc cpp kernel-devel kernel-headers;

if [ "$distro" != 'redhat' ]; then
  yum -y clean all;
fi

# Clean up network interface persistence
rm -f /etc/udev/rules.d/70-persistent-net.rules;
mkdir -p /etc/udev/rules.d/70-persistent-net.rules;
rm -f /lib/udev/rules.d/75-persistent-net-generator.rules;
rm -rf /dev/.udev/;
rm -rf /etc/udev/rules.d/70-*;

for ndev in `ls -1 /etc/sysconfig/network-scripts/ifcfg-*`; do
    if [ "`basename $ndev`" != "ifcfg-lo" ]; then
        sed -i '/^HWADDR/d' "$ndev";
        sed -i '/^UUID/d' "$ndev";
    fi
done

# new-style network device naming for centos7
if grep -q -i "release 8" /etc/redhat-release ; then
  # radio off & remove all interface configration
  /bin/systemctl stop NetworkManager.service
  for ifcfg in `ls /etc/sysconfig/network-scripts/ifcfg-* | grep -v ifcfg-lo | | grep -v dummy` ; do
    rm -f $ifcfg
  done
  rm -rf /var/lib/NetworkManager/*
fi

# delete any logs that have built up during the install
find /var/log/ -name *.log -exec rm -f {} \;

rm -rf /etc/ssh/ssh_host_*
hostnamectl set-hostname localhost.localdomain
rm -rf /etc/udev/rules.d/70-*
