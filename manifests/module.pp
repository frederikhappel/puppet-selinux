# == Define: selinux::module
#
# Compile and install a selinux policy module.
#
# What it does:
# - mange file /usr/share/selinux/packages/<name>.te which is comes from $source
# - compile and manage it
#
# === Parameters
#
# [*source*]
#   a puppet fileserver url to a te-file, the policy module source
#
# [*ensure*]
#   create or remove selinux policy module (default "present")
#
# === Examples
#
# selinux::module {
#   "snmpCheckMysql" :
#     source => "puppet:///modules/mysql/selinux_snmpCheckMysql.te"
# }
#
# This will compile and install the module "snmpCheckMysql" from source
# "puppet:///modules/mysql/selinux_snmpCheckMysql.te"
#
define selinux::module (
  $source,
  $ensure = present
) {
  # validate parameters
  validate_puppet_source($source)
  validate_re($ensure, '^(present|absent)$')

  # dependency to baseclass
  require ::selinux

  # define variables
  $srcfile = "${selinux::params::pkgdir}/${name}.te"
  $modfile = "${selinux::params::pkgdir}/${name}.mod"
  $pkgfile = "${selinux::params::pkgdir}/${name}.pp"

  if $selinux::params::enabled {
    case $ensure {
      present : {
        # create source for module
        file {
          $srcfile :
            source => $source,
            owner => 0,
            group => 0,
            notify => Exec["selinuxModule_CreateMod_${name}"] ;
        }

        exec {
          "selinuxModule_TestMod_${name}" : # test if module was built already
            command => "echo 'not found, trigger build'",
            unless => "test -e ${modfile}",
            require => File[$srcfile],
            notify => Exec["selinuxModule_CreateMod_${name}"] ;

          "selinuxModule_CreateMod_${name}" : # compile module
            command => "checkmodule -M -m -o ${modfile} ${srcfile} && semodule_package -o ${pkgfile} -m ${modfile}",
            cwd => $selinux::params::pkgdir,
            refreshonly => true,
            require => Package["checkpolicy", "policycoreutils"] ;
        }

        # install and enable module
        selmodule {
          $name :
            selmoduledir => $selinux::params::pkgdir,
            syncversion => true,
            require => Exec["selinuxModule_CreateMod_${name}"] ;
        }
      }

      absent : {
        # remove and disable module
        selmodule {
          $name :
            ensure => absent,
            selmoduledir => $selinux::params::pkgdir ;
        }

        # remove leftovers
        file {
          [$srcfile, $modfile, $pkgfile] :
            ensure => absent,
            require => Selmodule[$name] ;
        }
      }
    }
  } else {
    debug("SELinux is disabled")
  }
}
