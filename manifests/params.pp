# ds_389::params
#
# This class sets parameters according to platform
#
class ds_389::params {

  case $::osfamily {
    'Debian': {
      $ssl_dir = '/etc/ssl'
      $user_shell = '/bin/false'
      $nsstools_package_name = 'libnss3-tools'
      $setup_ds = 'setup-ds'
      $cacert_rehash = 'c_rehash'
      $limits_config_dir = '/etc/default'
      case $::operatingsystemmajrelease {
        '8', '9', '16.04': {
          $service_type = 'systemd'
          $ssl_version_min_support = true
        }
        default: {
          $service_type = 'init'
          $ssl_version_min_support = false
        }
      }
    }
    'RedHat': {
      $ssl_dir = '/etc/pki/tls/certs'
      $user_shell = '/sbin/nologin'
      $nsstools_package_name = 'nss-tools'
      $setup_ds = 'setup-ds.pl'
      $cacert_rehash = 'cacertdir_rehash'
      $limits_config_dir = '/etc/sysconfig'
      case $::operatingsystemmajrelease {
        '7': {
          $service_type = 'systemd'
          $ssl_version_min_support = true
        }
        default: {
          $service_type = 'init'
          $ssl_version_min_support = false
        }
      }
    }
    default: {
      fail("${::osfamily} not supported")
    }
  }
}
