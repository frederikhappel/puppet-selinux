# == Define: selinux::setseportperm
#
# Set and persist a given selinux context for a given port and protocol.
#
# === Parameters
#
# [*port*]
#   the port number to manage (default $name)
#
# [*protocol*]
#   the protocol of that port
#
# [*context*]
#   the selinux context for that port
#
# [*ensure*]
#   create or remove selinux rule (default "present")
#
# === Examples
#
# selinux::setseportperm {
#   "8080" :
#     protocol => "tcp",
#     context => "http_port_t",
# }
#
define selinux::setseportperm (
  $port = $name,
  $protocol,
  $context,
  $ensure = present
) {
  # validate parameters
  validate_ip_port($port)
  validate_string($protocol, $context)
  validate_re($ensure, '^(present|absent)$')

  # dependency to baseclass
  require ::selinux

  if $selinux::params::enabled {
    $semanage = 'nice -n 15 semanage'
    case $ensure {
      present: {
        # add selinux policy for port
        exec {
          "selinuxSetseportperm_${port}_${protocol}_${context}" :
            command => "${semanage} port -a -t ${context} -p ${protocol} ${port} || semanage port -m -t ${context} -p ${protocol} ${port}",
            unless => "${semanage} port -l | grep '^${context}[[:blank:]][[:blank:]]*${protocol}[[:blank:]][0-9*,[[:blank:]]*]*${port}'" ;
        }
      }

      absent: {
        # remove selinux policy for port
        exec {
          "selinuxSetseportperm_${port}_${protocol}_${context}" :
            command => "${semanage} port -d -t ${context} -p ${protocol} ${port}",
            onlyif => "${semanage} port -l | grep '^${context}[[:blank:]][[:blank:]]*${protocol}[[:blank:]][0-9*,[[:blank:]]*]*${port}'" ;
        }
      }
    }
  } else {
    debug("SELinux is disabled")
  }
}
