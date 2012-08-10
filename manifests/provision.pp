node master {
  $hostname = 'master.puppetlabs.vm'
  $hostaddr = '172.16.0.1'
  $ipaddr   = '172.16.0.2'

  package { 'vim':
    ensure  => installed,
    tag     => ['razor','puppet'],
  }

  #### DHCP
  class { 'dhcp':
    dnsdomain   => [ 'localdomain' ],
    nameservers => [ $ipaddr ],
    ntpservers  => [ $ipaddr ],
    interfaces  => [ 'eth1' ],
    pxeserver   => [ $ipaddr ],
    pxefilename => 'pxelinux.0',
    require     => Exec['apt_update'],
    tag         => ['razor']
  }
  dhcp::pool { 'localdomain':
    network     => '172.16.0.0',
    mask        => '255.255.255.0',
    range       => '172.16.0.100 172.16.0.200',
    gateway     => $hostaddr,
    tag         => ['razor'],
  }

  ### Give us sudo
  sudo::conf { 'vagrant':
    content => 'vagrant ALL=(ALL) NOPASSWD: ALL',
    tag    => ['razor','puppet'],
  }

  ### Add the puppetlabs repo
  apt::source { 'puppetlabs':
    location   => 'http://apt.puppetlabs.com',
    repos      => 'main',
    key        => '4BD6EC30',
    key_server => 'pgp.mit.edu',
    tag       => ['puppet'],
  }

  Exec["apt_update"] -> Package <| |>

  ### Add bind -- hack
  package { 'bind9':
    ensure  => 'installed',
    tag     => ['razor'],
    require => Class['dhcp'],
  }

  service { 'bind9':
    ensure  => 'running',
    enable  => 'true',
    require => Package['bind9'],
    tag    => ['razor'],
  }

  file { '/etc/bind/named.conf.local':
    content => 'zone "puppetlabs.vm" { type master; file "/etc/bind/puppetlabs.vm"; };',
    require => Package['bind9'],
    tag     => ['razor'],
  }

  file { '/etc/bind/puppetlabs.vm':
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
    tag     => ['razor'],
  }

  file {'/etc/bind/named.conf.options':
    content => 'options { directory "/var/cache/bind"; dnssec-validation auto; auth-nxdomain no; listen-on-v6 { any; }; forwarders { 8.8.8.8; 8.8.4.4; }; };',
    require => File['/etc/bind/named.conf.local'],
    notify  => Service['bind9'],
    tag    => ['razor'],
  }
  ####### razor
  class { 'razor':
    address => $ipaddr,
    tag     => ['razor'],
    require => Class['tftp'], 
  }
  
  ### run tftp as a service
  class {'tftp': 
    inetd => false,
    tag   => ['razor'],
  }

  ####### puppetdb
  class { 'puppetdb::server':
    tag => ['puppet'],
  }

  exec { '/etc/init.d/puppetdb stop && /usr/sbin/puppetdb-ssl-setup && /etc/init.d/puppetdb start':
    creates => '/etc/puppetdb/ssl/keystore.jks',
    require => [Class['puppetdb::server'],Class['puppet::master']],
    tag     => ['puppet'],
  }

  ###### puppet
  class { 'puppet::master':
    autosign                  => true,
    storeconfigs              => true,
    storeconfigs_dbserver     => $hostname,
    tag                       => ['puppet'],
  }

  class { 'puppet::agent':
    puppet_server             => $hostname,
    tag                       => ['puppet'],
  }

  ###links puppet to modules here
  file {'/etc/puppet/manifests':
    ensure  => link,
    target  => '/tmp/vagrant-puppet/manifests',
    require => Package['puppetmaster'],
    force   => true,
    tag     => ['puppet'],
  }

  file {'/etc/puppet/modules':
    ensure  => link,
    target  => '/tmp/vagrant-puppet/modules-0',
    require => Package['puppetmaster'],
    force   => true,
    tag     => ['puppet'],
  }

  #####HACK TO SETUP IP ADDRESS IN RAZOR
  exec {"/bin/sed -i 's/image_svc_host: .*/image_svc_host: $ipaddr/' /opt/razor/conf/razor_server.conf ":
    unless  => "/bin/grep 'mage_svc_host: $ipaddr' /opt/razor/conf/razor_server.conf -q",
    require => Class['razor'],
    tag     => ['razor'],
  }

  exec {"/bin/sed -i 's#mk_uri: http://.*:8026#mk_uri: http://$ipaddr:8026#' /opt/razor/conf/razor_server.conf ":
    unless  => "/bin/grep 'mk_uri: http://$ipaddr:8026' /opt/razor/conf/razor_server.conf -q",
    require => Class['razor'],
    tag     => ['razor'],
  }

  rz_image { 'precise_image':
    ensure   => present,
    type     => 'os',
    version  => '12.04',
    source   => '/tmp/images/ubuntu-12.04-server-amd64.iso',
    tag      => ['ubuntu'],
  }

  rz_model { 'precise_model':
    ensure      => present,
    description => 'Ubuntu Precise Model',
    image       => 'precise_image',
    metadata    => {'domainname' => 'puppetlabs.lan', 'hostname_prefix' => 'openstack', 'root_password' => 'puppet'},
    template    => 'ubuntu_precise',
    tag         => ['ubuntu'],
  }

  rz_policy { 'precise_policy':
    ensure   => 'present',
    broker   => 'none',
    model    => 'precise_model',
    enabled  => 'true',
    tags     => ['virtualbox_vm'],
    template => 'linux_deploy',
    tag      => ['ubuntu'],
    maximum  => 10,
  }
}
