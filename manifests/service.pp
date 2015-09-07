define monit::service (
  $source = undef,
  $content = undef,
  $manageinitd = true,
  $subscribe = undef,
  $ensure = present
) {
  # validate parameters
  validate_string($source, $content)
  validate_bool($manageinitd)
  validate_re($ensure, '^(present|absent)$')

  # define variables
  $cfgfile = "${monit::params::cfgddir}/${name}.conf"

  # create service configuration
  case $ensure {
    present : {
      File {
        owner => 0,
        group => 0,
      }
      if $source != undef and is_puppet_resource($source) {
        file {
          $cfgfile :
            ensure => $ensure,
            source => $source,
            mode => '0644',
            notify => Exec['monitReloadConfiguration'] ;
        }
      } elsif($content != undef) {
        file {
          $cfgfile :
            ensure => $ensure,
            content => $content,
            mode => '0644',
            notify => Exec['monitReloadConfiguration'] ;
        }
      } else {
        fail('either specify $source or $content')
      }
    }

    default : {
        file {
          $cfgfile :
            ensure => absent,
            notify => Service[$monit::params::service_name] ;
        }
    }
  }

  # try to restart service if needed
  if ($subscribe != undef) {
    exec {
      "monitService_restart_${name}" :
        command => "monit restart ${name}",
        onlyif => "monit status | grep ${name}",
        refreshonly => true,
        require => Exec['monitReloadConfiguration'],
        subscribe => $subscribe ;
    }
  }

  # manage init.d
  if $manageinitd {
    service {
      $name :
        enable => $ensure ? { present => false, default => true } ;
    }
  }
}
