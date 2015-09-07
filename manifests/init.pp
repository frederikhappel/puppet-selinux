# == Class: selinux
#
# Setup selinux tools.
#
# What it does:
# - install packages libselinux-utils, policycoreutils, checkpolicy, selinux-policy,
#   selinux-policy-targeted
# - create directory /usr/share/selinux/packages
# - install /usr/share/selinux/packages/compile.sh to manually compile a module
# - setup system service restorecond
#
# === Examples
#
# include selinux
#
class selinux (
  $selinux_mode = 'enforcing',
  $selinux_type = 'targeted',
  $auditd_enabled = true,
  $auditd_logging = false
) inherits selinux::params {
  # validate parameters
  validate_re($selinux_mode, '^(enforcing|permissive|disabled)$')
  validate_re($selinux_type, '^(targeted|mls)$')
  validate_bool($auditd_enabled, $auditd_logging)

  # include classes
  include selinux::nagios

  # package management
  # automatic update might break services
  package {
    ['libselinux-utils', 'policycoreutils', 'checkpolicy', 'audit'] :
      ensure => present ;

    ['selinux-policy', "selinux-policy-${selinux_type}"] :
      ensure => present ;

    'setools' :
      ensure => present,
      name => $::operatingsystemmajrelease ? { 5 => 'setools', default => 'setools-console' } ;
  }

  # create directories
  File {
    owner => 0,
    group => 0,
    require => Package['selinux-policy'],
  }
  file {
    [$cfgdir, $pkgdir] :
      ensure => directory,
      mode => '0644' ;

    $sysconfig :
      content => template('selinux/selinux.sysconfig.erb'),
      mode => '0644' ;

    "${pkgdir}/compile.sh" :
      source => 'puppet:///modules/selinux/compile.sh',
      mode => '0755' ;

    $auditd_sysconfig :
      content => template('selinux/auditd.sysconfig.erb'),
      mode => '0640',
      require => Package['audit'] ;
  }

  # define restorecond service
  $service_status = $enabled ? { false => stopped, default => running }
  $service_enabled = $selinux_mode ? { 'disabled' => false, default => true }
  service {
    $service_name :
      ensure => $service_status,
      enable => $service_enabled,
      hasrestart => true,
      hasstatus => $::operatingsystemmajrelease > 5,
      require => Package['policycoreutils'] ;

    $auditd_service_name :
      ensure => $auditd_enabled ? { false => stopped, default => $service_status },
      enable => ($auditd_enabled and $service_enabled) ,
      hasrestart => true,
      hasstatus => true,
      subscribe => File[$auditd_sysconfig] ;
  }
}
