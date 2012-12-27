class statsd ($graphite_host, $graphite_port = 2003, $port = 8125, $debug = 1, $flush_interval = 60000) {
  Package { ensure => "installed", }
  Exec { path => ["/usr/bin", "/bin", "/sbin"], }

/*
  exec {
    "clone nodejs":
      cwd     => "/usr/local/src",
      command => "git clone git://github.com/joyent/node.git",
      creates => "/usr/local/src/node",
      require => Package['git'];

    "build nodejs":
      cwd     => "/usr/local/src/node",
      command => "/usr/local/src/node/configure && make -j3",
      creates => "/usr/local/src/node/out/Release/node",
      require => Exec['clone nodejs'];

    "install nodejs":
      cwd     => "/usr/local/src/node",
      command => "make install",
      creates => "/usr/local/bin/node",
      require => Exec['build nodejs'];
  }
*/

  user { "node":
    ensure     => "present",
    gid        => "users",
    shell      => "/bin/bash",
    managehome => "true",
  }

  ## actually nodejs:
  include meteor

  exec { "npm-statsd":
    command     => "npm install -g statsd",
    #refreshonly => true,
    creates     => "/usr/lib/node_modules/statsd/bin/statsd",
    require     => Class['meteor'],
    #require    => Exec['install nodejs'],
    # you can trigger an update of statsd package by changing /etc/statsd.js, bit of a hack but works
    subscribe   => File["/etc/statsd.js"],
  }

  file {
    "/etc/init/statsd.conf":
      ensure => file,
      owner  => "root",
      group  => "root",
      mode   => "0644",
      source => "puppet:///modules/statsd/etc/init/statsd.conf";

    "/usr/local/bin/statsd_client.pl":
      ensure => file,
      owner  => "root",
      group  => "root",
      mode   => "0755",
      source => "puppet:///modules/statsd/usr/local/bin/statsd_client.pl";

    "/etc/statsd.js":
      ensure  => file,
      content => template("statsd/etc/statsd.js.erb");
  }

  exec { "restart-statsd":
    command     => "stop statsd; start statsd",
    refreshonly => true,
    require     => [
          Class['meteor'],
          #Exec['install nodejs'],
          Exec["npm-statsd"],
          ],
    subscribe   => [
          File['/etc/statsd.js'],
          Exec['npm-statsd'],
          ],
  }
}
