# ds_389::add
#
# Adds an ldif file to a 389 ds instance.
#
# @summary Adds an ldif file to a 389 ds instance.
#
# @example Adding an ldif file with required params.
#   ds_389::add { 'add_example_1':
#     server_id    => 'foo',
#     source       => 'puppet:///path/to/file.ldif',
#     root_dn      => 'cn=Directory Manager',
#     root_dn_pass => 'supersecure',
#   }
#
# @example Adding an ldif file when using a template.
#   ds_389::add { 'add_example_2':
#     server_id    => 'foo',
#     content      => template('profiles/template.ldif.erb'),
#     root_dn      => 'cn=Directory Manager',
#     root_dn_pass => 'supersecure',
#   }
#
# @example Adding an ldif file when using all params.
#   ds_389::add { 'add_example_3':
#     server_id       => 'foo',
#     source          => '/path/to/file.ldif',
#     root_dn         => 'cn=Directory Manager',
#     root_dn_pass    => 'supersecure',
#     server_host     => 'foo.example.com',
#     server_ssl_port => 1636,
#     user            => 'custom_user',
#     group           => 'custom_group',
#   }
#
# @param server_id The 389 ds instance name. Required.
# @param root_dn The bind DN to use when calling ldapadd. Required.
# @param root_dn_pass The password to use when calling ldapadd. Required.
# @param content The content value to use for the ldif file. Required, unless providing the source.
# @param source The source path to use for the ldif file. Required, unless providing the content.
# @param server_host The host to use when calling ldapadd. Default: $::fqdn
# @param server_ssl_port The port to use when calling ldapadd. Default: 636
# @param user The owner of the created ldif file. Default: $::ds_389::user
# @param group The group of the created ldif file. Default: $::ds_389::group
#
define ds_389::add(
  String                            $server_id,
  String                            $root_dn,
  Variant[String,Sensitive[String]] $root_dn_pass,
  Optional[String]                  $content         = undef,
  Optional[String]                  $source          = undef,
  String                            $server_host     = $::fqdn,
  Integer                           $server_ssl_port = 636,
  String                            $user            = $::ds_389::user,
  String                            $group           = $::ds_389::group,
) {
  include ::ds_389

  if !$content and !$source {
    fail('ds_389::add requires a value for either content or source')
  }

  file { "/etc/dirsrv/slapd-${server_id}/${name}.ldif":
    ensure  => file,
    mode    => '0440',
    owner   => $user,
    group   => $group,
    content => $content,
    source  => $source,
  }
  exec { "Add ldif ${name}: ${server_id}":
    command => "ldapadd -h ${server_host} -p ${server_ssl_port} -x -D \"${root_dn}\" -w ${root_dn_pass} -f /etc/dirsrv/slapd-${server_id}/${name}.ldif ; touch /etc/dirsrv/slapd-${server_id}/${name}.done", # lint:ignore:140chars
    path    => '/usr/bin:/bin',
    creates => "/etc/dirsrv/slapd-${server_id}/${name}.done",
    require => File["/etc/dirsrv/slapd-${server_id}/${name}.ldif"],
  }
}
