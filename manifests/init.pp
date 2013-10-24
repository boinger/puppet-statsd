class statsd (
  $graphite_host,
  $graphite_port  = 2003,
  $suffix         = '',
  $bind_interface = '127.0.0.1',
  $port           = 8125,
  $debug          = 1,
  $flush_interval = 5,
  $version        = '0.12'
  ) {

  if (!$suffix) {
    $suffix = $hostname
  }

  Exec { path => ["/usr/bin", "/bin", "/sbin"], }
  Package { ensure => "installed", }
  File {
    ensure => present,
    owner  => "root",
    group  => "root",
    mode   => 0644,
  }

  $statsd_gems = [
    'bundler',
    'daemons',
    'eventmachine',
    'parseconfig',
    'sysexits',
  ]

  package { $statsd_gems:
    provider => 'gem',
    require  => [Package['ruby'], Package['rubygems'], ];
  }

  exec {
    "clone ruby-statsdserver":
      cwd     => "/usr/local/src",
      command => "git clone git://github.com/boinger/ruby-statsdserver.git",
      creates => "/usr/local/src/ruby-statsdserver",
      require => Package['git'];

    "build ruby-statsdserver":
      cwd     => "/usr/local/src/ruby-statsdserver",
      command => "git pull && gem build statsd.gemspec && gem uninstall statsdserver",
      creates => "/usr/local/src/ruby-statsdserver/statsdserver-${version}.gem",
      require => Exec['clone ruby-statsdserver'];

    "install ruby-statsdserver":
      cwd     => "/usr/local/src/ruby-statsdserver",
      command => "gem install statsdserver",
      creates => "/usr/bin/statsd",
      require => [Exec['build ruby-statsdserver'], ];
  }

  file {
    "/data/log/statsd":
      ensure  => directory,
      owner   => "statsd",
      mode    => 0755,
      require => File['/data/log'];
  }

  statsd::service {
    "statsd-${port}":
      graphite_host  => $graphite_host,
      graphite_port  => $graphite_port,
      suffix         => $suffix,
      bind_interface => $bind_interface,
      listen_port    => $port,
      debug          => $debug,
      flush_interval => $flush_interval;
  }

}
