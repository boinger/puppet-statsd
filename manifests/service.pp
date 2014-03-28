define statsd::service (
  $graphite_host,
  $graphite_port  = 2003,
  $suffix,
  $prefix         = 'stats',
  $bind_interface = '127.0.0.1',
  $listen_port    = 8125,
  $debug          = 0,
  $flush_interval = 10,
  $comment        = false,
  ) {

  Exec { path => ["/usr/bin", "/bin", "/sbin"], }
  File {
    ensure => present,
    owner  => "root",
    group  => "root",
    mode   => 0644,
  }

  exec {
    "restart-${name}":
      command     => "stop ${name} ; start ${name}",
      refreshonly => true,
      require     => Service["${name}"],
      subscribe   => [ File["/etc/${name}.conf"], File["/etc/init/${name}.conf"], ];
  }

  file {
    "/etc/init/${name}.conf":
      content => template("statsd/etc/init/statsd.conf.erb");

    "/etc/${name}.conf":
      content => template("statsd/etc/statsd.conf.erb");

    "/data/log/statsd/${name}.log":
      ensure  => file,
      owner   => "statsd",
      require => File['/data/log/statsd'];
  }

  service {
    $name:
      ensure     => 'running',
      hasrestart => true,
      hasstatus  => true,
      restart    => "/sbin/restart ${name}",
      start      => "/sbin/start ${name}",
      stop       => "/sbin/stop ${name}",
      status     => "/sbin/status ${name} | grep '/running' 1>/dev/null 2>&1",
      require    => [
        File["/etc/init/${name}.conf"],
        File["/etc/${name}.conf"],
        File["/data/log/statsd/"],
        ];
  }
}
