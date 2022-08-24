// Set AWS & HCP ENV
packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.1"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

data "amazon-ami" "ubuntu-server-east" {
  region = var.region
  filters = {
    name                = var.image_name
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }
  most_recent = true
  owners      = ["099720109477"]
}

source "amazon-ebs" "ubuntu-server-east" {
  region          = var.region
  source_ami      = data.amazon-ami.ubuntu-server-east.id
  instance_type   = "t2.small"
  ssh_username    = "ubuntu"
  ssh_agent_auth  = false
  ami_name        = "rryjewski-hashicups-demo-{{timestamp}}_v${var.version}"
  tags            = var.aws_tags
  ami_regions     = ["us-east-1", "us-east-2"]
  skip_create_ami = false
}

// source "azure-arm" "ubuntu-server-east" {
//   client_id       = "${var.client_id}"
//   subscription_id = "${var.subscription_id}"
//   client_secret   = "${var.client_secret}"
//   location        = "eastus2"
//   #build_resource_group_name = "${var.resource_group}"

//   os_type         = "Linux"
//   os_disk_size_gb = 50
//   image_publisher = "Canonical"
//   image_offer     = "0001-com-ubuntu-server-focal"
//   image_sku       = "20_04-lts-gen2"

//   managed_image_name                = "rryjewski-ubuntu-server-{{timestamp}}"
//   managed_image_resource_group_name = "${var.resource_group}"
//   vm_size                           = "Standard_D4_v4"
// }


build {
  hcp_packer_registry {
    bucket_name   = "hashicups-frontend-ubuntu"
    description   = "HCP Packer Demo"
    bucket_labels = var.aws_tags
    build_labels = {
      "build-time"   = timestamp(),
      "build-source" = basename(path.cwd)
    }
  }

  sources = ["source.amazon-ebs.ubuntu-server-east"]

  // sources = ["source.amazon-ebs.ubuntu-server-east", "source.azure-arm.ubuntu-server-east"]

  ## HashiCups
  # Add startup script that will run hashicups on instance boot
  provisioner "file" {
    source      = "setup-deps-hashicups.sh"
    destination = "/tmp/setup-deps-hashicups.sh"
  }

  # Move temp files to actual destination
  # Must use this method because their destinations are protected 
  provisioner "shell" {
    inline = [
      "sudo cp /tmp/setup-deps-hashicups.sh /var/lib/cloud/scripts/per-boot/setup-deps-hashicups.sh",
    ]
  }
  
  // // -deprovision vs -deprovision+user : The latter removes all user accounts
  // provisioner "shell" {
  //   only = ["source.azure-arm.ubuntu-server-east"]
  //   execute_command = "chmod +x {{ .Path }}; {{ .Vars }} sudo -E sh '{{ .Path }}'"
  //   inline          = ["/usr/sbin/waagent -force -deprovision && export HISTSIZE=0 && sync"]
  //   inline_shebang  = "/bin/sh -x"
  // }
}