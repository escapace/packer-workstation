# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "escapace/workstation"

  config.vm.define "virtualbox" do |virtualbox|
    virtualbox.vm.hostname = "escapace-workstation"

    config.vm.provider :virtualbox do |v|
      v.gui = false
      v.memory = 4096
      v.cpus = 2
    end

    config.vm.network "forwarded_port", guest: 8080, host: 8080
  end
end
