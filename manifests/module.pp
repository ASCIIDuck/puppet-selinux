# Definition: selinux::module
#
# Description
#  This class will either install or uninstall a SELinux module from a running system. 
#  This module allows an admin to keep .te files in text form in a repository, while 
#  allowing the system to compile and manage SELinux modules.   
#
#  Concepts incorporated from: 
#  http://stuckinadoloop.wordpress.com/2011/06/15/puppet-managed-deployment-of-selinux-modules/
#
# Parameters:
#   - $ensure: (present|absent) - sets the state for a module
#   - $mod_dir: The directory compiled modules will live on a system (default: /usr/share/selinux)
#   - $mode: Allows an admin to set the SELinux status. (default: enforcing)
#   - $source: the source file (either a puppet URI or local file) of the SELinux .te module
#
# Actions:
#  Compiles a module using 'checkmodule' and 'semodule_package'.
#
# Requires:
#  - SELinux
#
# Sample Usage:
#  selinux::module{ 'apache':
#    ensure => 'present',
#    source => 'puppet:///modules/selinux/apache.te', 
#  }
#
define selinux::module(
  $ensure  = 'present',
  $mod_dir = '/usr/share/selinux',
  $source
) {
  # Set Resource Defaults
  File {
    owner => 'root',
    group => 'root',
    mode  => '0644',
  }

  # Only allow refresh in the event that the initial .te file is updated.
  Exec {
    path         => '/sbin:/usr/sbin:/bin:/usr/bin',
    resfreshonly => 'true',
    cwd          => "${mod_dir}",
  }

  ## Begin Configuration
  file { $mod_dir:
    ensure => directory,
  }
  file { "${mod_dir}/${name}.te":
    ensure => $ensure,
    source => $source,
    tag    => 'selinux-module',
  }
  file { "${mod_dir}/${name}.mod":
    tag => ['selinux-module-build', 'selinux-module'],
  }
  file { "${mod_dir}/${name}.pp":
    tag => ['selinux-module-build', 'selinux-module'],
  }

  # Specific executables based on present or absent.
  case $ensure {
    present: {
      exec { "${name}-buildmod":
        command => "checkmodule -M -m -o ${name}.mod ${name}.te",
        notify  => Exec["${name}-buildpp"],
      }
      exec { "${name}-buildpp":
        command => "semodule_package -m ${name}.mod -o ${name}.pp",
        notify  => Exec["${name}-install"],
      }
      exec { "${name}-install":
        command => 'semodule -i ${name}.pp',
      }

      # Set dependency ordering
      File["${mod_dir}/${name}.te"]
      ~> Exec["${name}-buildmod"]
      ~> Exec["${name}-buildpp"]
      ~> Exec["${name}-install"]
      -> File<| tag == 'selinux-module-build' |>
    }
    absent: {
      exec { "${name}-remove":
        command => "semodule -r ${name}.pp > /dev/null 2>&1",
      }

      # Set dependency ordering
      Exec["${name}-remove"]
      -> File<| tag == 'selinux-module' |>
    }
    default: {
      fail("Invalid status for SELinux Module: ${ensure}")
    }
  }
}
