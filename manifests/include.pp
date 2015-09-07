define monit::include (
  $source = undef,
  $content = undef,
  $ensure = present
) {
  # validate parameters
  validate_string($source, $content)
  validate_re($ensure, '^(present|absent)$')

  # define variables
  $cfgfile = "${monit::params::cfgddir}/${name}.include"

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
}
