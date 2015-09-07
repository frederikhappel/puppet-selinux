# == Define: selinux::setsefileperm
#
# Set and persist a given selinux context for a given file or directory.
#
# === Parameters
#
# [*path*]
#   the path to manage (default $name)
#
# [*context*]
#   the selinux context for that path
#
# [*isdirectory*]
#   is the given path a directory (default 'false')
#
# [*ensure*]
#   create or remove selinux rule (default 'present')
#
# === Examples
#
# selinux::setsefileperm {
#   '/etc/hosts' :
#     context => 'etc_t'
# }
#
define selinux::setsefileperm (
  $path = $name,
  $context,
  $isdirectory = false,
  $relabel_on_boot = false,
  $ensure = present
) {
  # validate parameters
  validate_string($path, $context)
  validate_bool($isdirectory, $relabel_on_boot)
  validate_re($ensure, '^(present|absent)$')

  # dependency to baseclass
  require ::selinux

  if $selinux::params::enabled {
    $semanage = 'nice -n 15 semanage'
    # do we manage a directory
    $path_stripped = regsubst($path, '/$', '')
    if $isdirectory {
      $target = "${path_stripped}(/.*)?"
    } else {
      $target = $path_stripped
    }
    $path_cleaned = regsubst($path_stripped, '\.\*', '*', 'G')

    case $ensure {
      present: {
        # add selinux file context
        exec {
          "selinuxSetsefileperm_${path_cleaned}" :
            command => "${semanage} fcontext -a -t ${context} '${target}' && restorecon -rF ${path_cleaned} || true",
#            onlyif => "nice -n 15 seinfo -t${context} | grep ${context}",
            unless => "ls -Z ${path_cleaned} | grep ${context}",
        }
      }

      absent: {
        # remove selinux file context
        exec {
          "selinuxSetsefileperm_${path_cleaned}" :
            command => "${semanage} fcontext -d -t ${context} '${target}' && restorecon -rF ${path_cleaned} || true",
            onlyif => "ls -Z ${path_cleaned} | grep ${context}" ;
        }
      }
    }

    # explicitly relable on boot
    file_line {
      "selinuxSetsefileperm_rc.local_${path_cleaned}" :
        ensure => $relabel_on_boot ? { true => $ensure, default => absent },
        line => "/sbin/restorecon -rF ${path_cleaned}",
        path => '/etc/rc.local' ;
    }
  } else {
    debug('SELinux is disabled')
  }
}
