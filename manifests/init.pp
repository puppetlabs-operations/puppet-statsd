class statsd(
  $graphiteserver   = $statsd::params::graphiteserver,
  $graphiteport     = $statsd::params::graphiteport,
  $backends         = $statsd::params::backends,
  $address          = $statsd::params::address,
  $listenport       = $statsd::params::listenport,
  $flushinterval    = $statsd::params::flushinterval,
  $percentthreshold = $statsd::params::percentthreshold,
  $ensure           = $statsd::params::ensure,
  $service_ensure   = $statsd::params::service_ensure,
  $provider         = $statsd::params::provider,
  $config           = $statsd::params::config,
  $statsjs          = $statsd::params::statsjs,
  $init_script      = $statsd::params::init_script,
  $node_manage      = $statsd::params::node_manage,
  $node_version     = $statsd::params::node_version,
) inherits statsd::params {

  if $node_manage == true {
    class { '::nodejs': version => $node_version }
  }

  case $service_ensure {
    'running': {
      $service_enable = true
      $file_ensure = 'present'
    }
    'stopped': {
      $service_enable = false
      $file_ensure = 'absent'
    }
    default: {
      fail("ensure must be 'running' or 'stopped', not ${service_ensure}")
    }
  }

  package { 'statsd':
    ensure   => $ensure,
    provider => $provider,
    notify  => Service['statsd'],
  }

  $configfile  = '/etc/statsd/localConfig.js'
  $logfile     = '/var/log/statsd/statsd.log'

  file { '/etc/statsd':
    ensure => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  } ->
  file { $configfile:
    content => template('statsd/localConfig.js.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    notify  => Service['statsd'],
  }
  file { '/etc/init.d/statsd':
    ensure  => $file_ensure,
    source  => $init_script,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    notify  => Service['statsd'],
  }
  file {  '/etc/default/statsd':
    ensure  => $file_ensure,
    content => template('statsd/statsd-defaults.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    notify  => Service['statsd'],
  }
  file { '/var/log/statsd':
    ensure => directory,
    owner  => 'nobody',
    group  => 'root',
    mode   => '0770',
  }
  file { '/usr/local/sbin/statsd':
    source  => 'puppet:///modules/statsd/statsd-wrapper',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    notify  => Service['statsd'],
  }

  service { 'statsd':
    ensure    => $service_ensure,
    enable    => $service_enable,
    hasstatus => true,
    pattern   => 'node .*stats.js',
    require   => File['/var/log/statsd'],
  }
}
