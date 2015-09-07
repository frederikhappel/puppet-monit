class monit (
  $interval = 2,
  $runstyle = 'service', # service/inittab/off
  $adminuser = undef,
  $adminpass = undef,
  $adminport = 2812,
  $purgecfgddir = true,
  $ensure = present
) inherits monit::params {
  # validate parameters
  validate_integer($interval)
  validate_re($runstyle, '^(service|inittab|off)$')
  validate_string($adminuser, $adminpass)
  validate_ip_port($adminport)
  validate_bool($purgecfgddir)
  validate_re($ensure, '^(present|absent)$')

  # package management
  # TODO: yum repo ['dag']
  package {
    $package_name :
      ensure => ensure_latest($ensure) ; # repo dag
  }

  # include classes
  class {
    'monit::nagios' :
      ensure => $ensure ;
  }

  # manage monit inittab entry
  # TODO: fix for centos 5
  if $runstyle == 'inittab' and $::operatingsystemmajrelease == 5 {
    $runstyle_real = 'service'
  } else {
    $runstyle_real = $runstyle
  }
  sysinit::value {
    $service_name :
      ensure => $runstyle_real ? { 'inittab' => $ensure, default => absent },
      inittabid => 'mo',
      runlevels => '2345',
      action => 'respawn',
      process => "/usr/bin/monit -c ${cfgfile}",
      require=> Package[$package_name] ;
  }

  # cleanup monit events
  cron {
    'deletemonitevents' :
      ensure => $ensure,
      command => "find ${eventdir} -maxdepth 1 -daystart -mtime +3 -type f | xargs rm -f",
      hour => 0,
      minute => 15,
      require => Package[$package_name] ;
  }

  # configure monit
  case $ensure {
    present: {
      # define reload command
      exec {
        'monitReloadConfiguration' :
          command => 'monit reload',
          refreshonly => true,
          subscribe => [File[$cfgfile], Package[$package_name]] ;

        'monitMonitorAll' :
          command => 'monit monitor all',
          onlyif => 'monit status | grep -i "monitoring status[[:blank:]]*not monitored"',
          environment => 'LC_ALL=C',
          require => Package[$package_name] ;
      }

      # create directories and configuration
      File {
        require => Package[$package_name],
      }
      file {
        [$rundir, $eventdir] :
          ensure => directory,
          mode => '0755' ;

        $cfgddir :
          ensure => directory,
          mode => '0644',
          recurse => $purgecfgddir,
          purge => $purgecfgddir ;

        $cfgfile :
          content => template('monit/monit.conf.erb'),
          mode => '0600' ;

        '/etc/monitrc' :
          ensure => $cfgfile,
          force => true ;
      }

      # realize all defined services
      Monit::Service <||>
      Monit::Include <||>
      Monit::Check::Process <||>

      # manage service
      service {
        $service_name :
          ensure => $runstyle_real ? { 'service' => running, default => undef },
          enable => $runstyle_real == 'service',
          hasrestart => true,
          hasstatus => true,
          subscribe => [File[$cfgfile], Package[$package_name]] ;
      }
    }

    absent: {
      # delete leftovers completely (with data)
      file {
        [$rundir, $eventdir, $cfgddir, $cfgfile] :
          ensure => absent,
          force => true,
          recurse => true ;
      }
    }
  }
}
