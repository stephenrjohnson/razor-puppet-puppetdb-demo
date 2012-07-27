# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant::Config.run do |config|

  config.vm.define :master do |box_config|
    box_config.vm.box = 'precise64'
    box_config.vm.host_name  = 'master.puppetlabs.vm'
    box_config.vm.box_url = 'http://files.vagrantup.com/precise64.box'
    box_config.vm.customize ["modifyvm", :id, "--memory", 1024]
    box_config.vm.customize ["modifyvm", :id, "--name", 'master.puppetlabs.vm']
    box_config.vm.network :hostonly, '172.16.0.2', :adapter => 2
    box_config.vm.boot_mode = 'gui'
    box_config.vm.provision :puppet do | puppet|
	    puppet.manifest_file = 'master.pp'
	    puppet.manifests_path = 'manifests'
	    puppet.module_path = 'modules'
    end
  end

  config.vm.define :agent1 do |box_config|
    box_config.vm.box = 'agent1'
    box_config.vm.box_url = 'https://github.com/downloads/benburkert/bootstrap-razor/pxe-blank.box'
    box_config.vm.boot_mode = 'gui'
    box_config.ssh.port = 2222
    box_config.vm.customize ["modifyvm", :id, "--name", 'agent1.puppetlabs.vm']
  end

  config.vm.define :agent2 do |box_config|
    box_config.vm.box = 'agent2'
    box_config.vm.box_url = 'https://github.com/downloads/benburkert/bootstrap-razor/pxe-blank.box'
    box_config.vm.boot_mode = 'gui'
    box_config.ssh.port = 2222
    box_config.vm.customize ["modifyvm", :id, "--name", 'agent2.puppetlabs.vm', "--macaddress1", 'auto']
  end

end
