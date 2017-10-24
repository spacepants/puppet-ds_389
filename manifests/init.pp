# ds_389
#
# Installs and manages 389 Directory Server
#
# @summary Installs and manages 389 Directory Server
#
# @example
#   include ds_389
#
# @param package_name Name of the 389 ds package to install. Default: '389-ds-base'
# @param package_ensure 389 ds package state. Default 'installed'
# @param user User account 389 ds should run as. Default: 'dirsrv'
# @param group Group account 389 ds user should belong to. Default: 'dirsrv'
# @param cacerts_path Target directory the 389 ds certs should be exported to. Default: '/etc/openldap/cacerts'
# @param home_dir Home directory for the 389 ds user account. Default: '/usr/share/dirsrv'
# @param instances A hash of ds_389::instance resources. Optional.
#
class ds_389 (
  String               $package_name   = '389-ds-base',
  String               $package_ensure = 'installed',
  String               $user           = 'dirsrv',
  String               $group          = 'dirsrv',
  Stdlib::Absolutepath $cacerts_path   = '/etc/openldap/cacerts',
  Stdlib::Absolutepath $home_dir       = '/usr/share/dirsrv',
  Optional[Hash]       $instances      = undef,
) inherits ds_389::params {

  class { '::ds_389::install': }
  if $instances {
    $instances.each |$instance_name, $params| {
      ::ds_389::instance { $instance_name:
        root_dn           => $params['root_dn'],
        suffix            => $params['suffix'],
        cert_db_pass      => $params['cert_db_pass'],
        root_dn_pass      => $params['root_dn_pass'],
        group             => $params['group'],
        user              => $params['user'],
        server_id         => $params['server_id'],
        server_host       => $params['server_host'],
        server_port       => $params['server_port'],
        server_ssl_port   => $params['server_ssl_port'],
        subject_alt_names => $params['subject_alt_names'],
        replication       => $params['replication'],
        ssl               => $params['ssl'],
        ssl_version_min   => $params['ssl_version_min'],
        schema_extensions => $params['schema_extensions'],
        modify_ldifs      => $params['modify_ldifs'],
        add_ldifs         => $params['add_ldifs'],
        base_load_ldifs   => $params['base_load_ldifs'],
        require           => Class['::ds_389::install'],
      }
    }
  }
}
