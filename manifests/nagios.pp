class monit::nagios (
  $ensure = present
) {
  # validate parameters
  validate_re($ensure, '^(present|absent)$')

  # create nrpe and service checks
  @nagios::nrpe::check {
    'check_monit_process' :
      ensure => $ensure,
      source => 'check_procs',
      commands => {
        check_monit_process => '-C monit -c 1:2',
      },
      manage_script => false ;

    'check_monit_services' :
      ensure => $ensure,
      source => 'puppet:///modules/monit/check_monit.sh',
      commands => {
        check_monit_services => '',
      } ;
  }
  @activecheck::service::nrpe {
    'monit_process' :
      ensure => $ensure,
      check_interval_in_seconds => 60,
      check_command => 'check_monit_process' ;

    'monit_services' :
      ensure => $ensure,
      check_interval_in_seconds => 180,
      check_command => 'check_monit_services',
      dependent_service_description => 'monit_process' ;
  }
}
