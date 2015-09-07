class selinux::params {
  # define variables
  $service_name = 'restorecond'
  $auditd_service_name = 'auditd'
  $enabled = str2bool($::selinux)

  # files and directories
  $cfgdir = '/etc/selinux'
  $pkgdir = '/usr/share/selinux/packages'

  $sysconfig = "${cfgdir}/config"
  $auditd_sysconfig = '/etc/sysconfig/auditd'
}
