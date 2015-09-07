define monit::check::process (
  $pidfile,
  $cycles = 1,
  $start_program,
  $stop_program,
  $start_timeout_in_seconds = 0,
  $stop_timeout_in_seconds = 0,
  $conditions = [],
  $manageinitd = true,
  $subscribe = undef,
  $ensure = present
) {
  # validate parameters
  validate_absolute_path($pidfile)
  validate_string($start_program, $stop_program)
  validate_integer($cycles, $start_timeout_in_seconds, $stop_timeout_in_seconds)
  validate_array($conditions)
  validate_bool($manageinitd)
  if $subscribe != undef {
    validate_puppet_resource($subscribe)
  }
  validate_re($ensure, '^(present|absent)$')

  # define actual check
  @monit::service {
    $name :
      ensure => $ensure,
      content => template('monit/process.conf.erb'),
      manageinitd => $manageinitd,
      subscribe => $subscribe ;
  }
}
