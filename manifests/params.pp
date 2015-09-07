class monit::params {
  # define variables
  $service_name = 'monit'
  $package_name = 'monit'

  # directories and files
  $rundir = '/var/lib/monit'
  $eventdir = "${rundir}/events"
  $cfgddir = '/etc/monit.d'
  $cfgfile = '/etc/monit.conf'
}
