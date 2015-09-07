# == Define: selinux::setsebool
#
# Set and persist a given selinux boolean.
#
# === Parameters
#
# [*ensure*]
#   enable or disable the boolean
#
# === Examples
#
# selinux::setsebool {
#   "httpd_enable_cgi" :
#     ensure => present ;
# }
#
# This will set the boolean httpd_enable_cgi to "on"
#
define selinux::setsebool (
  $ensure
) {
  # dependency to baseclass
  require ::selinux

  if $selinux::params::enabled {
    case $ensure {
      /^(on|true|present)$/ : {
        $value = "on"
      }

      /^(off|false|absent)$/ : {
        $value = "off"
      }

      default: {
        fail("unknown ensure value ${ensure}")
      }
    }

    # actually set value
    exec {
      "selinuxSetsebool_${name}" :
        command => "setsebool -P ${name} ${value}",
        onlyif => "getsebool ${name}",
        unless => "getsebool ${name} | grep -i '${value}$'",
        environment => "LC_ALL=C" ;
    }
  }
}
