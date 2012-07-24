node master {
  $hostname = 'master.puppetlabs.vm'
  $ipaddr   = '172.16.0.2'
  $hostaddr = '172.16.0.1'
  $razv = "0.9.0.4"
  $mkimage = "rz_mk_dev-image.$razv.iso"

  package { 'vim': ensure => installed, }
  
  #### DHCP 
  class { dhcp:
    dnsdomain   => [ 'localdomain' ],
    nameservers => [ $hostaddr ],
    ntpservers  => [ $hostaddr ],
    interfaces  => [ 'eth1' ],
    pxeserver   => [ $ipaddr ],
    pxefilename => 'pxelinux.0',
  }
  dhcp::pool { 'localdomain':
    network     => '172.16.0.0',
    mask        => '255.255.0.0',
    range       => '172.16.0.100 172.16.0.200',
    gateway     => $ipaddr,
  }
  
  ### Give us sudo
  sudo::conf { 'vagrant':
    content => 'vagrant ALL=(ALL) NOPASSWD: ALL',
  }
  
  ### Add the puppetlabs repo
  apt::source { 'puppetlabs':
    location   => 'http://apt.puppetlabs.com',
    repos      => 'main',
    key        => '4BD6EC30',
    key_server => 'pgp.mit.edu',
    before     => [ Class['puppetdb::terminus'], Class['puppet'], Class['puppetdb::server'] ],
  }

  ### Add bind -- hack
  package { 'bind9':
   ensure => 'installed'
  }

  service { 'bind9':
      ensure  => 'running',
      enable  => 'true',
      require => Package['bind9'],
  }

  file {'/etc/bind/named.conf.local':
      content => 'zone "puppetlabs.vm" { type master; file "/etc/bind/puppetlabs.vm"; };',
      require => Package['bind9'],
  }

  file {'/etc/bind/puppetlabs.vm':
       content =>  "\$TTL 604800 
@       IN      SOA     master.puppetlabs.vm   master.puppetlabs.vm. (
2007011501
7200
120
2419200
604800)
        IN      NS      $hostname.
master  IN      A       $ipaddr
puppet  IN      A       $ipaddr
",
         require => File['/etc/bind/named.conf.local'],
         notify  => Service['bind9'],
  }
  ####### razor
  class { razor: }
  
  rz_image { $mkimage:
    ensure  => 'present',
    type    => 'mk',
    source  => "http://github.com/downloads/puppetlabs/Razor/$mkimage",
    require => Service['razor'],
  }
  
  ####### puppetdb
  class { puppetdb::server: }
  class { puppetdb::terminus: puppetdb_host => $hostname } 

  exec {'/etc/init.d/puppetdb stop && /usr/sbin/puppetdb-ssl-setup && /etc/init.d/puppetdb start':
      creates => '/etc/puppetdb/ssl/keystore.jks',
      require => Class['puppetdb::terminus'],
  }
  
  ###### puppet
  class { puppet: 
  	  master                    => true, 
	  agent                     => false,  
	  puppet_master_package     => "puppetmaster", 
      puppet_server             => $hostname, 
	  storeconfigs              => true, 
	  storeconfigs_dbadapter    => "puppetdb",
      storeconfigs_dbserver     => $hostname,
  }

  ###links puppet to modules here

  file {'/etc/puppet/manifests':
    ensure  => link,
    target  => "/tmp/vagrant-puppet/manifests",
    require => Package['puppetmaster'],
    force   => true,
  }

  file {'/etc/puppet/modules':
    ensure  => link,
    target  => "/tmp/vagrant-puppet/modules-0",
    require => Package['puppetmaster'],
    force   => true,
  }
}
