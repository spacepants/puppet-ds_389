# ds_389::instance
#
# Manages a 389 ds instance.
#
# @summary Manages a 389 ds instance.
#
# @example A basic instance with required params.
#   ds_389::instance { 'foo':
#     root_dn      => 'cn=Directory Manager',
#     suffix       => 'dc=example,dc=com',
#     cert_db_pass => 'secret',
#     root_dn_pass => 'supersecure',
#     server_id    => 'specdirectory',
#   }
#
# @param root_dn The root dn to ensure. Required.
# @param root_dn_pass The root dn password to ensure. Required.
# @param cert_db_pass The certificate db password to ensure. Required.
# @param suffix The LDAP suffix to use. Required.
# @param group The group for the instance. Default: $::ds_389::group
# @param user The user for the instance. Default: $::ds_389::user
# @param server_id The server identifier for the instance. Default: $::hostname
# @param server_host The fqdn for the instance. Default: $::fqdn
# @param server_port The port to use for non-SSL traffic. Default: 389
# @param server_ssl_port The port to use for SSL traffic. Default: 636
# @param subject_alt_names An array of subject alt names, if using self-signed certificates. Optional.
# @param replication A replication config hash. See replication.pp. Optional.
# @param ssl An ssl config hash. See ssl.pp. Optional.
# @param ssl_version_min The minimum TLS version the instance should support. Optional.
# @param schema_extensions A hash of schemas to ensure. See schema.pp. Optional.
# @param modify_ldifs A hash of ldif modify files. See modify.pp. Optional. Optional.
# @param add_ldifs A hash of ldif add files. See add.pp. Optional.
# @param base_load_ldifs A hash of ldif add files to load after all other config files have been added. Optional.
#
define ds_389::instance(
  String                            $root_dn,
  Variant[String,Sensitive[String]] $root_dn_pass,
  Variant[String,Sensitive[String]] $cert_db_pass,
  String                            $suffix,
  String                            $group                 = $::ds_389::group,
  String                            $user                  = $::ds_389::user,
  String                            $server_id             = $::hostname,
  String                            $server_host           = $::fqdn,
  Integer                           $server_port           = 389,
  Integer                           $server_ssl_port       = 636,
  Optional[Array]                   $subject_alt_names     = undef,
  Optional[Hash]                    $replication           = undef,
  Optional[Hash]                    $ssl                   = undef,
  Optional[String]                  $ssl_version_min       = undef,
  Optional[Hash]                    $schema_extensions     = undef,
  Optional[Hash]                    $modify_ldifs          = undef,
  Optional[Hash]                    $add_ldifs             = undef,
  Optional[Hash]                    $base_load_ldifs       = undef,
) {
  include ::ds_389

  $instance_path = "/etc/dirsrv/slapd-${server_id}"
  exec { "setup ds: ${server_id}":
    command => "${::ds_389::params::setup_ds} --silent General.FullMachineName=${server_host} General.SuiteSpotGroup=${group} General.SuiteSpotUserID=${user} slapd.InstallLdifFile=none slapd.RootDN=\"${root_dn}\" slapd.RootDNPwd=${root_dn_pass} slapd.ServerIdentifier=${server_id} slapd.ServerPort=${server_port} slapd.Suffix=${suffix}", # lint:ignore:140chars
    path    => '/usr/sbin:/usr/bin:/sbin:/bin',
    creates => $instance_path,
    notify  => Exec["stop ${server_id} to create new token"],
  }
  if $::ds_389::params::service_type == 'systemd' {
    $service_stop_command = "/bin/systemctl stop dirsrv@${server_id}"
    $service_restart_command = "/bin/systemctl restart dirsrv@${server_id}"
  }
  else {
    $service_stop_command = "service dirsrv stop ${server_id}"
    $service_restart_command = "service dirsrv restart ${server_id}"
  }
  exec { "stop ${server_id} to create new token":
    command     => "${service_stop_command} ; sleep 2",
    refreshonly => true,
    path        => '/usr/sbin:/usr/bin:/sbin:/bin',
    before      => File["${instance_path}/pin.txt"],
  }
  file { "${instance_path}/pin.txt":
    ensure  => file,
    mode    => '0440',
    owner   => $user,
    group   => $group,
    content => "Internal (Software) Token:${root_dn_pass}\n",
    require => Exec["setup ds: ${server_id}"],
    notify  => Exec["restart ${server_id} to pick up new token"],
  }
  # if we have existing certs, create cert db and import certs
  if $ssl {
    # concat bundle
    concat::fragment { "${server_id}_cert":
      target => "${server_id}_cert_bundle",
      source => $ssl['cert_path'],
      order  => '0',
    }
    concat::fragment { "${server_id}_ca_bundle":
      target => "${server_id}_cert_bundle",
      source => $ssl['ca_bundle_path'],
      order  => '1',
    }
    concat::fragment { "${server_id}_key":
      target => "${server_id}_cert_bundle",
      source => $ssl['key_path'],
      order  => '2',
    }
    concat { "${server_id}_cert_bundle":
      mode   => '0600',
      path   => "${::ds_389::params::ssl_dir}/${server_id}-bundle.pem",
      notify => Exec["Create pkcs12 cert: ${server_id}"],
    }

    # create pkcs12 cert
    exec { "Create pkcs12 cert: ${server_id}":
      command     => "openssl pkcs12 -export -password pass:${cert_db_pass} -name ${server_host} -in ${::ds_389::params::ssl_dir}/${server_id}-bundle.pem -out ${::ds_389::params::ssl_dir}/${server_id}.p12", # lint:ignore:140chars
      path        => '/usr/bin:/bin',
      refreshonly => true,
      notify      => Exec["Create cert DB: ${server_id}"],
    }

    exec { "Create cert DB: ${server_id}":
      command     => "pk12util -i ${::ds_389::params::ssl_dir}/${server_id}.p12 -d ${instance_path} -W ${cert_db_pass} -K ${root_dn_pass}", # lint:ignore:140chars
      path        => '/usr/bin:/bin',
      refreshonly => true,
      before      => Exec["Add trust for server cert: ${server_id}"],
    }
    $ssl['ca_cert_names'].each |$index, $cert_name| {
      exec { "Add trust for CA${index}: ${server_id}":
        command => "certutil -M -n \"${cert_name}\" -t CT,, -d ${instance_path}",
        path    => '/usr/bin:/bin',
        unless  => "certutil -L -d ${instance_path} | grep \"${cert_name}\" | grep \"CT\"",
        require => Exec["Create cert DB: ${server_id}"],
        notify  => Exec["Export CA cert ${index}: ${server_id}"],
      }
      # - export ca cert
      exec { "Export CA cert ${index}: ${server_id}":
        cwd     => $instance_path,
        command => "certutil -d ${instance_path} -L -n \"${cert_name}\" -a > ${server_id}CA${index}.pem",
        path    => '/usr/bin:/bin',
        creates => "${instance_path}/${server_id}CA${index}.pem",
      }
      # - copy ca certs to openldap
      file { "${::ds_389::cacerts_path}/${server_id}CA${index}.pem":
        ensure  => file,
        source  => "${instance_path}/${server_id}CA${index}.pem",
        require => Exec["Export CA cert ${index}: ${server_id}"],
        notify  => Exec["Rehash cacertdir: ${server_id}"],
      }
    }

    $ssl_cert_name = $ssl['cert_name']
    exec { "Add trust for server cert: ${server_id}":
      command => "certutil -M -n \"${ssl['cert_name']}\" -t u,u,u -d ${instance_path}",
      path    => '/usr/bin:/bin',
      unless  => "certutil -L -d ${instance_path} | grep \"${ssl['cert_name']}\" | grep \"u,u,u\"",
      notify  => Exec["Export server cert: ${server_id}"],
    }
  }

  # otherwise gen certs and add to db
  else {
    if $subject_alt_names {
      $san_string = join($subject_alt_names, ',')
      $sans = "-8 ${san_string}"
    }
    else {
      $sans = undef
    }
    # - create noise file
    $temp_noise_file = "/tmp/noisefile-${server_id}"
    $temp_pass_file = "/tmp/passfile-${server_id}"
    $rand_int = fqdn_rand(32)
    exec { "Generate noise file: ${server_id}":
      command     => "echo ${rand_int} | sha256sum | awk \'{print \$1}\' > ${temp_noise_file}",
      path        => '/usr/bin:/bin',
      refreshonly => true,
      subscribe   => Exec["stop ${server_id} to create new token"],
      notify      => Exec["Generate password file: ${server_id}"],
    }
    # - create pwd file
    exec { "Generate password file: ${server_id}":
      command     => "echo ${root_dn_pass} > ${temp_pass_file}",
      path        => '/usr/bin:/bin',
      refreshonly => true,
      notify      => Exec["Create cert DB: ${server_id}"],
    }
    # - create cert db
    exec { "Create cert DB: ${server_id}":
      command     => "certutil -N -d ${instance_path} -f ${temp_pass_file}",
      path        => '/usr/bin:/bin',
      refreshonly => true,
      notify      => Exec["Generate key pair: ${server_id}"],
    }
    # - generate key pair
    exec { "Generate key pair: ${server_id}":
      command     => "certutil -G -d ${instance_path} -g 4096 -z ${temp_noise_file} -f ${temp_pass_file}",
      path        => '/usr/bin:/bin',
      refreshonly => true,
      notify      => Exec["Make ca cert and add to database: ${server_id}"],
    }
    # - make certs and add to database
    exec { "Make ca cert and add to database: ${server_id}":
      cwd         => $instance_path,
      command     => "certutil -S -n \"${server_id}CA\" -s \"cn=${server_id}CA,dc=${server_host}\" -x -t \"CT,,\" -v 120 -d ${instance_path} -k rsa -z ${temp_noise_file} -f ${temp_pass_file} ; sleep 2", # lint:ignore:140chars
      path        => '/usr/bin:/bin',
      refreshonly => true,
      notify      => [
        Exec["Make server cert and add to database: ${server_id}"],
        Exec["Clean up temp files: ${server_id}"],
        Exec["Add trust for CA: ${server_id}"],
      ],
    }
    exec { "Add trust for CA: ${server_id}":
      command => "certutil -M -n \"${server_id}CA\" -t CT,, -d ${instance_path}",
      path    => '/usr/bin:/bin',
      unless  => "certutil -L -d ${instance_path} | grep \"${server_id}CA\" | grep \"CT\"",
      notify  => Exec["Export CA cert: ${server_id}"],
    }
    # - make server cert and add to database
    $ssl_cert_name = "${server_id}Cert"
    exec { "Make server cert and add to database: ${server_id}":
      cwd         => $instance_path,
      command     => "certutil -S -n \"${ssl_cert_name}\" -m 101 -s \"cn=${server_host}\" -c \"${server_id}CA\" -t \"u,u,u\" -v 120 -d ${instance_path} -k rsa -z ${temp_noise_file} -f ${temp_pass_file} ${sans} ; sleep 2", # lint:ignore:140chars
      path        => '/usr/bin:/bin',
      refreshonly => true,
      notify      => [
        Exec["Set permissions on database directory: ${server_id}"],
        Exec["Clean up temp files: ${server_id}"],
        Exec["Add trust for server cert: ${server_id}"],
      ],
    }
    exec { "Add trust for server cert: ${server_id}":
      command => "certutil -M -n \"${ssl_cert_name}\" -t u,u,u -d ${instance_path}",
      path    => '/usr/bin:/bin',
      unless  => "certutil -L -d ${instance_path} | grep \"${ssl_cert_name}\" | grep \"u,u,u\"",
      notify  => Exec["Export server cert: ${server_id}"],
    }
    # - set perms on database directory
    exec { "Set permissions on database directory: ${server_id}":
      command     => "/bin/chown ${user}:${group} ${instance_path}",
      refreshonly => true,
    }
    # - export ca cert
    exec { "Export CA cert: ${server_id}":
      cwd     => $instance_path,
      command => "certutil -d ${instance_path} -L -n \"${server_id}CA\" -a > ${server_id}CA.pem",
      path    => '/usr/bin:/bin',
      creates => "${instance_path}/${server_id}CA.pem",
    }
    # - copy ca cert to openldap
    file { "${::ds_389::cacerts_path}/${server_id}CA.pem":
      ensure  => file,
      source  => "${instance_path}/${server_id}CA.pem",
      require => Exec["Export CA cert: ${server_id}"],
      notify  => Exec["Rehash cacertdir: ${server_id}"],
    }
    # - remove temp files (pwd and noise)
    exec { "Clean up temp files: ${server_id}":
      command     => "/bin/rm -f ${temp_noise_file} ${temp_pass_file}",
      refreshonly => true,
    }
  }
  # - export server cert
  exec { "Export server cert: ${server_id}":
    cwd     => $instance_path,
    command => "certutil -d ${instance_path} -L -n \"${ssl_cert_name}\" -a > ${server_id}Cert.pem",
    path    => '/usr/bin:/bin',
    creates => "${instance_path}/${server_id}Cert.pem",
  }
  file { "${::ds_389::cacerts_path}/${server_id}Cert.pem":
    ensure  => file,
    source  => "${instance_path}/${server_id}Cert.pem",
    require => Exec["Export server cert: ${server_id}"],
    notify  => Exec["Rehash cacertdir: ${server_id}"],
  }
  # - rehash certs
  exec { "Rehash cacertdir: ${server_id}":
    command     => "${::ds_389::params::cacert_rehash} ${::ds_389::cacerts_path}",
    path        => '/usr/sbin:/usr/bin:/sbin:/bin',
    refreshonly => true,
    notify      => Exec["restart ${server_id} to pick up new token"],
  }
  exec { "restart ${server_id} to pick up new token":
    command     => "${service_restart_command} ; sleep 2",
    path        => '/usr/sbin:/usr/bin:/sbin:/bin',
    refreshonly => true,
  }

  # schema extensions
  if $schema_extensions {
    $schema_extensions.each |$filename, $source| {
      ::ds_389::schema { $filename:
        server_id => $server_id,
        user      => $user,
        group     => $group,
        source    => $source,
        require   => Exec["restart ${server_id} to pick up new token"],
        before    => Service["dirsrv@${server_id}"],
      }
    }
  }

  # ldif ssl
  ::ds_389::ssl { $server_id:
    cert_name       => $ssl_cert_name,
    root_dn         => $root_dn,
    root_dn_pass    => $root_dn_pass,
    server_host     => $server_host,
    server_port     => $server_port,
    user            => $user,
    group           => $group,
    ssl_version_min => $ssl_version_min,
    notify          => Service["dirsrv@${server_id}"],
  }

  # service
  ::ds_389::service { $server_id: }

  # ldif replication
  if $replication {
    ::ds_389::replication { $server_id:
      bind_dn             => $replication['bind_dn'],
      replication_pass    => $replication['replication_pass'],
      replication_user    => $replication['replication_user'],
      role                => $replication['role'],
      id                  => $replication['id'],
      purge_delay         => $replication['purge_delay'],
      suppliers           => $replication['suppliers'],
      hubs                => $replication['hubs'],
      consumers           => $replication['consumers'],
      excluded_attributes => $replication['excluded_attributes'],
      init_suppliers      => $replication['init_suppliers'],
      init_hubs           => $replication['init_hubs'],
      init_consumers      => $replication['init_consumers'],
      root_dn             => $root_dn,
      root_dn_pass        => $root_dn_pass,
      suffix              => $suffix,
      server_host         => $server_host,
      server_ssl_port     => $server_ssl_port,
      user                => $user,
      group               => $group,
      require             => Service["dirsrv@${server_id}"],
      before              => Anchor["${name}_ldif_modify"],
    }
  }

  anchor { "${name}_ldif_modify":
    require => Service["dirsrv@${server_id}"],
  }

  # ldif modify
  if $modify_ldifs {
    $modify_ldifs.each |$filename, $source| {
      ::ds_389::modify { $filename:
        server_id       => $server_id,
        root_dn         => $root_dn,
        root_dn_pass    => $root_dn_pass,
        server_host     => $server_host,
        server_ssl_port => $server_ssl_port,
        source          => $source,
        user            => $user,
        group           => $group,
        tag             => "${server_id}_modify",
        require         => Anchor["${name}_ldif_modify"],
        before          => Anchor["${name}_ldif_add"],
      }
    }
  }

  anchor { "${name}_ldif_add": }

  # ldif add
  if $add_ldifs {
    $add_ldifs.each |$filename, $source| {
      ::ds_389::add { $filename:
        server_id       => $server_id,
        root_dn         => $root_dn,
        root_dn_pass    => $root_dn_pass,
        server_host     => $server_host,
        server_ssl_port => $server_ssl_port,
        source          => $source,
        user            => $user,
        group           => $group,
        tag             => "${server_id}_add",
        require         => Anchor["${name}_ldif_add"],
        before          => Anchor["${name}_ldif_base_load"],
      }
    }
  }

  anchor { "${name}_ldif_base_load": }

  # ldif base_load
  if $base_load_ldifs {
    $base_load_ldifs.each |$filename, $source| {
      ::ds_389::add { $filename:
        server_id       => $server_id,
        root_dn         => $root_dn,
        root_dn_pass    => $root_dn_pass,
        server_host     => $server_host,
        server_ssl_port => $server_ssl_port,
        source          => $source,
        user            => $user,
        group           => $group,
        tag             => "${server_id}_base_load",
        require         => Anchor["${name}_ldif_base_load"],
      }
    }
  }
}
