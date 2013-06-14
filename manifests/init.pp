class statsd (
  $graphite_host,
  $graphite_port  = 2003,
  $port           = 8125,
  $debug          = 1,
  $flush_interval = 5,
  $version        = '0.12'
  ) {

  Exec { path => ["/usr/bin", "/bin", "/sbin"], }
  Package { ensure => "installed", }
  File {
    ensure => present,
    owner  => "root",
    group  => "root",
    mode   => 0644,
  }

  $pencil_gems = [
    'bundler',
    'daemons',
    'eventmachine',
    'parseconfig',
    'sysexits',
  ]

  package { $pencil_gems:
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
      notify  => Exec['restart-statsd'],
      require => [Exec['build ruby-statsdserver'], ];

    "restart-statsd":
      command     => "stop statsd ; start statsd",
      refreshonly => true,
      require     => [ Exec["install ruby-statsdserver"], Service['statsd'], ],
      subscribe   => [ File['/etc/statsd.conf'], File['/etc/init/statsd.conf'], ];
  }

  file {
    "/etc/init/statsd.conf":
      source  => "puppet:///modules/statsd/etc/init/statsd.conf",
      require => User['statsd'];

    "/etc/statsd.conf":
      content => template("statsd/etc/statsd.conf.erb");

    "/data/log/statsd":
      ensure  => directory,
      owner   => "statsd",
      mode    => 0755,
      require => File['/data/log'];

    "/data/log/statsd/statsd.log":
      ensure  => file,
      owner   => "statsd",
      require => File['/data/log/statsd'];
  }

  service {
    'statsd':
      ensure     => 'running',
      hasrestart => true,
      hasstatus  => true,
      restart    => "/sbin/restart ${name}",
      start      => "/sbin/start ${name}",
      stop       => "/sbin/stop ${name}",
      status     => "/sbin/status ${name} | grep '/running' 1>/dev/null 2>&1",
      require    => [
        File['/etc/statsd.conf'],
        File['/data/log/statsd/statsd.log'],
        File['/etc/init/statsd.conf'],
        Exec['install ruby-statsdserver'],
        ];
  }
}
