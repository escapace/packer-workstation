variable "access_token" {
  type = string
}

variable "version" {
  type = string
}

variable "cpus" {
  type    = number
  default = 2
}

variable "disk_size" {
  type    = number
  default = 20480
}

variable "memory" {
  type    = number
  default = 2048
}

variable "name" {
  type    = string
  default = "centos-stream"
}

variable "iso_version" {
  type    = string
  default = "20201211"
}

variable "arch" {
  type    = string
  default = "x86_64"
}

variable "iso_checksum" {
  type    = string
  default = "24544c943c0f98f3096b027bb59a93b390853b2b3b538e13566515f9121be5fc"
}

# "timestamp" template function replacement
locals {
  timestamp    = regex_replace(timestamp(), "[- TZ:]", "")
  iso_filename = "CentOS-Stream-8-${var.arch}-${var.iso_version}-dvd1.iso"
}

source "virtualbox-iso" "stream" {
  boot_command         = ["<tab> text ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg<enter><wait>"]
  boot_wait            = "10s"
  disk_size            = var.disk_size
  guest_additions_path = "VBoxGuestAdditions_{{.Version}}.iso"
  guest_os_type        = "RedHat_64"
  headless             = true
  http_directory       = "http"
  iso_checksum         = "sha256:${var.iso_checksum}"
  iso_urls = [
    "CentOS-8.2.2004-x86_64-dvd1.iso",
    "http://mirror.facebook.net/centos/8-stream/isos/${var.arch}/${local.iso_filename}",
    "http://mirror.mobap.edu/centos/8-stream/isos/x86_64/${var.arch}/${local.iso_filename}",
    "http://mirror.cc.columbia.edu/pub/linux/centos/8-stream/isos/${var.arch}/${local.iso_filename}",
    "http://mirror.arizona.edu/centos/8-stream/isos/${var.arch}/${local.iso_filename}"
  ]
  shutdown_command        = "echo 'vagrant'|sudo -S /sbin/halt -h -p"
  ssh_password            = "vagrant"
  ssh_port                = 22
  ssh_timeout             = "10000s"
  ssh_username            = "vagrant"
  vboxmanage              = [["modifyvm", "{{.Name}}", "--memory", var.memory], ["modifyvm", "{{.Name}}", "--cpus", var.cpus]]
  virtualbox_version_file = ".vbox_version"
  vm_name                 = "packer-centos-stream"
}

build {
  sources = ["source.virtualbox-iso.stream"]

  provisioner "shell" {
    execute_command = "echo 'vagrant' | {{.Vars}} sudo -S -E bash '{{.Path}}'"
    script          = "./scripts/python.sh"
  }

  provisioner "ansible" {
    ansible_env_vars = ["ANSIBLE_CONFIG='./ansible/ansible.cfg'", "ANSIBLE_BECOME=True", "ANSIBLE_CALLBACK_WHITELIST=profile_roles", "ANSIBLE_HOST_KEY_CHECKING=False", "ANSIBLE_NOCOLOR=True", "ANSIBLE_RETRY_FILES_ENABLED=False", "ANSIBLE_SSH_ARGS='-o ForwardAgent=yes -o ControlMaster=auto -o ControlPersist=60s'"]
    groups           = ["provider_vagrant"]
    playbook_file    = "./ansible/bootstrap.yml"
    user             = "vagrant"
  }

  provisioner "shell" {
    execute_command   = "echo 'vagrant' | {{.Vars}} sudo -S -E bash '{{.Path}}'"
    expect_disconnect = true
    inline            = ["reboot"]
    timeout           = "10m0s"
  }
  provisioner "ansible" {
    ansible_env_vars = [
      "ANSIBLE_CONFIG='./ansible/ansible.cfg'",
      "ANSIBLE_BECOME=True",
      "ANSIBLE_CALLBACK_WHITELIST=profile_roles",
      "ANSIBLE_HOST_KEY_CHECKING=False",
      "ANSIBLE_NOCOLOR=True",
      "ANSIBLE_RETRY_FILES_ENABLED=False",
      "ANSIBLE_SSH_ARGS='-o ForwardAgent=yes -o ControlMaster=auto -o ControlPersist=60s'"
    ]
    groups        = ["provider_vagrant"]
    playbook_file = "./ansible/workstation.yml"
    user          = "vagrant"
  }

  provisioner "shell" {
    environment_vars  = ["HOME_DIR=/home/vagrant"]
    execute_command   = "echo 'vagrant' | {{.Vars}} sudo -S -E sh -eux '{{.Path}}'"
    expect_disconnect = true
    scripts           = ["./scripts/networking.sh", "./scripts/cleanup.sh", "./scripts/minimize.sh"]
  }

  post-processors {
    post-processor "vagrant" {
      output               = "builds/{{.Provider}}-centos8.box"
      vagrantfile_template = "vagrantfile.tpl"
    }

    post-processor "vagrant-cloud" {
      access_token = var.access_token
      box_tag      = "escapace/workstation"
      version      = var.version
    }
  }
}
