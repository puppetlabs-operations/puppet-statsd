class statsd(
  $graphiteserver   = 'localhost',
  $graphiteport     = '2003',
  $backends         = [ 'graphite' ],
  $address          = '0.0.0.0',
  $listenport       = '8125',
  $flushinterval    = '10000',
  $percentthreshold = ['90'],
  $ensure           = 'present',
  $provider         = 'npm',
  $node_module_dir  = '',
  $config           = { },
) {

  require nodejs

  package { 'statsd':
    ensure   => $ensure,
    provider => $provider,
    notify  => Service['statsd'],
  }

  $configfile  = '/etc/statsd/localConfig.js'
  $logfile     = '/var/log/statsd/statsd.log'

  # this cannot go in a params base class because that will be evaluated first
  # and the $node_module_dir and $provider vars won't be available yet
  case $::osfamily {
    'RedHat': {
      $init_script = 'puppet:///modules/statsd/statsd-init-rhel'
      if ! $node_module_dir {
        $statsjs = '/usr/lib/node_modules/statsd/stats.js'
      }
      else {
        $statsjs = "${node_module_dir}/statsd/stats.js"
      }
    }
    'Debian': {
      $init_script = 'puppet:///modules/statsd/statsd-init'
      if ! $node_module_dir {
        case $provider {
          'apt': {
            $statsjs = '/usr/share/statsd/stats.js'
          }
          'npm': {
            $statsjs = '/usr/lib/node_modules/statsd/stats.js'
          }
          default: {
            fail('Unsupported provider')
          }
        }
      }
      else {
        $statsjs = "${node_module_dir}/statsd/stats.js"
      }
    }
    default: {
      fail('Unsupported OS Family')
    }
  }

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
    source  => $init_script,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    notify  => Service['statsd'],
  }
  file {  '/etc/default/statsd':
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
    ensure    => running,
    enable    => true,
    hasstatus => true,
    pattern   => 'node .*stats.js',
    require   => File['/var/log/statsd'],
  }
}
