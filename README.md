Razor-vagrant-puppet-puppetdb-demo
==================================

# Origanl Idea

This demo is based on [razor-vagrant-demo] (https://github.com/benburkert/razor-vagrant-demo/).

## Step 1: Setup
First install virtual box

Then ensure that the the extension pack is installed:

 http://download.virtualbox.org/virtualbox/4.1.18/Oracle_VM_VirtualBox_Extension_Pack-4.1.18-78361.vbox-extpacks

It is unlikely that your virtualbox virtual machines will be able to PXE boot if the
extension pack is not installed.

## Step 2: Gems
Install the following gems

* Vagrant
* librarian-puppet

## Step 3: Install the puppet modules
librarian-puppet install

## Step 4: Launch the machines
Start the virtual machines this will take a long time the first time.
vagrant up

## Step 5: Update puppet manifest
The site.pp only contains information for master, update to include what you need for the clients.

## Step 6: Os images
Once the virtual machines have booted they will be ready to install. Add the razor os images and polices you need.
[razor-howto] (https://github.com/puppetlabs/Razor/wiki/)
