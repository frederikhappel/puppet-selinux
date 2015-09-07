class selinux::nagios (
  $ensure = present
) {
  # validate parameters
  validate_re($ensure, '^(present|absent)$')

  # configure nagios monitored service
  @nagios::nrpe::check {
    'check_selinux_process' :
      ensure => $ensure,
      source => 'check_procs',
      commands => {
        check_restorecond_process => '-C restorecond -c 1:1',
      },
      manage_script => false ;

    'check_selinux_status' :
      ensure => $ensure,
      selctx => 'nagios_unconfined_plugin_exec_t',
      source => 'puppet:///modules/selinux/nagios/check_selinux.sh',
      commands => {
        check_selinux_status => ''
      } ;
  }
  Activecheck::Service::Nrpe {
    ensure => $ensure,
    check_interval_in_seconds => 300,
  }
  @activecheck::service::nrpe {
    'selinux_restorecond' :
      ensure => $selinux::params::enabled ? { true => $ensure, default => absent },
      check_command => 'check_restorecond_process' ;

    'selinux_status' :
      notifications_enabled => false,
      check_command => 'check_selinux_status' ;
  }
}
