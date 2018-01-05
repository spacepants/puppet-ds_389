# 389 Directory Server module for Puppet

[![Build Status](https://travis-ci.org/spacepants/puppet-ds_389.svg?branch=master)](https://travis-ci.org/spacepants/puppet-ds_389)

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with ds_389](#setup)
    * [What ds_389 affects](#what-ds_389-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with ds_389](#beginning-with-ds_389)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Description

This module allows you to install and manage [389 Directory Server](http://directory.fedoraproject.org/), create and bootstrap 389 DS instances, configure SSL, replication, schema extensions and even load LDIF data.

SSL is enabled by default. If you already have an SSL cert you can provide the cert, key, and CA bundle, and they'll be imported into your instance. Otherwise, it'll generate self-signed certificates. Replication is supported for consumers, hubs, and suppliers (both master and multi-master), and there's a Puppet task to reinitialize replication.

## Setup

### What ds_389 affects

* Ensures the 389-ds-base and NSS tools packages are installed
* Increases file descriptors for 389 DS to 8192
* Ensures a user and group for the daemon
* Ensures a service for any 389 DS instances created

### Beginning with ds_389  

#### Examples

##### Basic example

```puppet
include ::ds_389
```

At a bare minimum, the module ensures that the 389 DS base package and NSS tools are installed, and increases the file descriptors for 389 DS.

You'll probably also want to create a 389 DS instance, though, which you can do by declaring a `ds_389::instance` resource:

```puppet
ds_389::instance { 'example':
  root_dn      => 'cn=Directory Manager',
  root_dn_pass => 'supersecret',
  suffix       => 'dc=example,dc=com',
  cert_db_pass => 'secret',
  server_id    => $::hostname,
}
```

## Usage

### Instances

The primary resource for configuring 389 DS is the `ds_389::instance` define.

In our previous example, we created an instance with the server ID set to the hostname of the node. For a node with a hostname of `foo`, this would create an instance at `/etc/dirsrv/slapd-foo` that listens on the default ports of 389 and 636 (for SSL).

#### SSL

If you have existing SSL certificates you'd like to use, you'd pass them in to the instance with the `ssl` parameter. It expects a hash with paths (either local file paths on the node or a puppet:/// path) for the PEM files for your certificate, key, and CA bundle. It also requires the certificate nickname for the cert and every CA in the bundle. (`pk12util` sets the nickname for the certificate to the friendly name of the cert in the pkcs12 bundle, and the nickname for each ca cert to "${the common name(cn) of the ca cert subject} - ${the organization(o) of the cert issuer}".)

To require StartTLS for non-SSL connections, you can pass in the `minssf` param to specify the minimum required encryption.

```puppet
ds_389::instance { 'example':
  root_dn      => 'cn=Directory Manager',
  root_dn_pass => 'supersecret',
  suffix       => 'dc=example,dc=com',
  cert_db_pass => 'secret',
  server_id    => $::hostname,
  minssf       => 128,
  ssl          => {
    'cert_path'      => 'puppet:///path/to/ssl_cert.pem',
    'key_path'       => 'puppet:///path/to/ssl_key.pem',
    'ca_bundle_path' => 'puppet:///path/to/ssl_ca.pem',
    'ca_cert_names'  => [
      'Certificate nickname for the first CA cert goes here',
      'Certificate nickname for another CA cert goes here',
    ],
    'cert_name'      => 'Certificate nickname goes here',
  },
}
```

#### Replication

If you need to set up replication, you'd pass in the replication config via the `replication` parameter. At a minimum, it expects a hash with the replication bind dn, replication bind dn password, and replication role (either 'consumer', 'hub', or 'supplier').

##### Consumer

For a consumer, with our previous example:

```puppet
ds_389::instance { 'example':
  root_dn      => 'cn=Directory Manager',
  root_dn_pass => 'supersecret',
  suffix       => 'dc=example,dc=com',
  cert_db_pass => 'secret',
  server_id    => $::hostname,
  replication  => {
    'replication_pass' => 'secret',
    'role'             => 'consumer',
  },
}
```

This would ensure that the replica bind dn and credentials are present in the instance.

##### Hub

For a hub, you can also pass in any consumers for the hub as an array of server IDs, and the replication agreement will be created and added to the instance.

```puppet
ds_389::instance { 'example':
  root_dn      => 'cn=Directory Manager',
  root_dn_pass => 'supersecret',
  suffix       => 'dc=example,dc=com',
  cert_db_pass => 'secret',
  server_id    => $::hostname,
  replication  => {
    'replication_pass' => 'secret',
    'role'             => 'hub',
    'consumers'        => [
      'consumer1',
      'consumer2',
    ],
  },
}
```

##### Supplier

For a supplier, you can pass in consumers, and also any hubs or other suppliers (if running in multi-master) that should be present in the instance. You'll also need to provide the replica ID for the supplier.

```puppet
ds_389::instance { 'example':
  root_dn      => 'cn=Directory Manager',
  root_dn_pass => 'supersecret',
  suffix       => 'dc=example,dc=com',
  cert_db_pass => 'secret',
  server_id    => $::hostname,
  replication  => {
    'replication_pass' => 'secret',
    'role'             => 'hub',
    'suppliers'        => [
      'supplier1',
      'supplier2',
    ],
    'hubs'             => [
      'hub1',
      'hub2',
    ],
    'consumers'        => [
      'consumer1',
      'consumer2',
    ],
  },
}
```

##### Initializing replication

Once replication has been configured on all of the desired nodes, you can initialize replication for consumers, hubs, and/or other suppliers by passing the appropriate parameters.

```puppet
ds_389::instance { 'example':
  root_dn      => 'cn=Directory Manager',
  root_dn_pass => 'supersecret',
  suffix       => 'dc=example,dc=com',
  cert_db_pass => 'secret',
  server_id    => $::hostname,
  replication  => {
    'replication_pass' => 'secret',
    'role'             => 'hub',
    'suppliers'        => [
      'supplier1',
      'supplier2',
    ],
    'hubs'             => [
      'hub1',
      'hub2',
    ],
    'consumers'        => [
      'consumer1',
      'consumer2',
    ],
    'init_suppliers'   => true,
    'init_hubs'        => true,
    'init_consumers'   => true,
  },
}
```

You can also initialize (or reinitialize) replication with the [Puppet task](#tasks).

#### Schema extensions

If you need to add any schema extensions, you can can pass those in with the `schema_extensions` parameter. It expects a hash with the desired ldif filename as the key, and a source reference (either via puppet:/// or an absolute path on the node). Note that schema filenames are typically prefixed with a number that indicates the desired schema load order.

```puppet
ds_389::instance { 'example':
  root_dn           => 'cn=Directory Manager',
  root_dn_pass      => 'supersecret',
  suffix            => 'dc=example,dc=com',
  cert_db_pass      => 'secret',
  schema_extensions => {
    '99example_schema' => 'puppet:///path/to/example_schema.ldif',
  },
}
```

#### Modifying existing LDIF data

If you need to modify any of the default ldif data, (typically configs) you can do so via the `modify_ldifs` parameter. It expects a hash with the desired ldif filename as the key, and a source reference (either via puppet:/// or an absolute path on the node). The ldif file is created and passed to ldapmodify to load it into the instance.

```puppet
ds_389::instance { 'example':
  root_dn      => 'cn=Directory Manager',
  root_dn_pass => 'supersecret',
  suffix       => 'dc=example,dc=com',
  cert_db_pass => 'secret',
  modify_ldifs => {
    'example_ldif_modify' => 'puppet:///path/to/example_modify.ldif',
  },
}
```

You can also declare those separately, by calling their define directly, but you'll need to provide the server id of the instance as well as the root dn and password.

```puppet
ds_389::modify { 'example_ldif_modify':
  server_id    => 'example',
  source       => 'puppet:///path/to/example_modify.ldif',
  root_dn      => 'cn=Directory Manager',
  root_dn_pass => 'supersecret',
}
```

#### Adding new LDIF data

If you need to add any new ldif data, (typically configs) you can do so via the `add_ldifs` parameter. It expects a hash with the desired ldif filename as the key, and a source reference (either via puppet:/// or an absolute path on the node). These function similarly to the modify_ldifs param, but are passed to ldapadd instead of ldapmodify.

```puppet
ds_389::instance { 'example':
  root_dn      => 'cn=Directory Manager',
  root_dn_pass => 'supersecret',
  suffix       => 'dc=example,dc=com',
  cert_db_pass => 'secret',
  add_ldifs    => {
    'example_ldif_add' => 'puppet:///path/to/example_add.ldif',
  },
}
```

You can also declare those separately, by calling their define directly, but you'll need to provide the server id of the instance as well as the root dn and password.

```puppet
ds_389::add { 'example_ldif_add':
  server_id    => 'example',
  source       => 'puppet:///path/to/example_add.ldif',
  root_dn      => 'cn=Directory Manager',
  root_dn_pass => 'supersecret',
}
```

#### Adding baseline LDIF data

If you need to load baseline ldif data that runs after any other ldif configuration changes, you can pass those in via the `base_load_ldifs` parameter.

```puppet
ds_389::instance { 'example':
  root_dn      => 'cn=Directory Manager',
  root_dn_pass => 'supersecret',
  suffix       => 'dc=example,dc=com',
  cert_db_pass => 'secret',
  base_load_ldifs    => {
    'example_ldif_baseline' => 'puppet:///path/to/example_baseline.ldif',
  },
}
```

Note that while you can declare these via the `ds_389::add` define, puppet's resource load ordering may potentially result in it attempting to add the ldif before a configuration change that it requires.

## Reference

### Classes

#### Public classes

* `ds_389`: Main class, manages the installation and configuration of 389-ds-base.

#### Private classes

* `ds_389::install`: Installs 389-ds-base.
* `ds_389::params`: Sets parameters according to platform.

#### Defined types

* `ds_389::instance`: The primary defined type. Creates and manages a 389 DS instance.
* `ds_389::add`: Adds ldif data via ldapadd to a 389 DS instance.
* `ds_389::modify`: Modifies ldif data via ldapmodify for a 389 DS instance.

The following defines are typically called from an instance.

* `ds_389::replication`: Sets up replication for a 389 DS instance.
* `ds_389::schema`: Adds a schema extension to a 389 DS instance.
* `ds_389::service`: Manages the service for a 389 DS instance.
* `ds_389::ssl`: Enables SSL for a 389 DS instance.

### Tasks
* `ds_389::reinit_consumer`: Reinitializes replication on a node.

### Parameters

#### ds_389
* `package_name`: Name of the 389 ds package to install. _Default: '389-ds-base'_
* `package_ensure`: 389 ds package state. _Default 'installed'_
* `user`: User account 389 ds should run as. _Default: 'dirsrv'_
* `group`: Group account 389 ds user should belong to. _Default: 'dirsrv'_
* `cacerts_path`: Target directory the 389 ds certs should be exported to. _Default: '/etc/openldap/cacerts'_
* `home_dir`: Home directory for the 389 ds user account. _Default: '/usr/share/dirsrv'_
* `instances`: A hash of ds_389::instance resources. _Optional._

#### ds_389::instance
* `root_dn`: The root dn to ensure. _Required._
* `root_dn_pass`: The root dn password to ensure. _Required._
* `cert_db_pass`: The certificate db password to ensure. _Required._
* `suffix`: The LDAP suffix to use. _Required._
* `group`: The group for the instance. *Default: $::ds_389::group*
* `user`: The user for the instance. *Default: $::ds_389::user*
* `server_id`: The server identifier for the instance. _Default: $::hostname_
* `server_host`: The fqdn for the instance. _Default: $::fqdn_
* `server_port`: The port to use for non-SSL traffic. _Default: 389_
* `server_ssl_port`: The port to use for SSL traffic. _Default: 636_
* `subject_alt_names`: An array of subject alt names, if using self-signed certificates. _Optional._
* `replication`: A replication config hash. See replication.pp. _Optional._
* `ssl`: An ssl config hash. See ssl.pp. _Optional._
* `minssf`: The minimum security strength for connections. _Optional._
* `ssl_version_min`: The minimum TLS version the instance should support. _Optional._
* `schema_extensions`: A hash of schemas to ensure. See schema.pp. _Optional._
* `modify_ldifs`: A hash of ldif modify files. See modify.pp. Optional. _Optional._
* `add_ldifs`: A hash of ldif add files. See add.pp. _Optional._
* `base_load_ldifs`: A hash of ldif add files to load after all other config files have been added. _Optional._

#### ds_389::modify
* `server_id`: The 389 ds instance name. _Required._
* `content`: The file content to use for the ldif file. _Required, unless providing the source._
* `source`: The source path to use for the ldif file. _Required, unless providing the content._
* `root_dn`: The bind DN to use when calling ldapmodify. _Required._
* `root_dn_pass`: The password to use when calling ldapmodify. _Required._
* `server_host`: The host to use when calling ldapmodify. _Default: $::fqdn_
* `server_ssl_port`: The port to use when calling ldapmodify. _Default: 636_
* `user`: The owner of the created ldif file. *Default: $::ds_389::user*
* `group`: The group of the created ldif file. *Default: $::ds_389::group*

#### ds_389::add
* `server_id`: The 389 ds instance name. _Required._
* `content`: The file content to use for the ldif file. _Required, unless providing the source._
* `source`: The source path to use for the ldif file. _Required, unless providing the content._
* `root_dn`: The bind DN to use when calling ldapadd. _Required._
* `root_dn_pass`: The password to use when calling ldapadd. _Required._
* `server_host`: The host to use when calling ldapadd. _Default: $::fqdn_
* `server_ssl_port`: The port to use when calling ldapadd. _Default: 636_
* `user`: The owner of the created ldif file. *Default: $::ds_389::user*
* `group`: The group of the created ldif file. *Default: $::ds_389::group*

#### ds_389::replication
* `replication_pass`: The bind dn password of the replication user. _Required._
* `root_dn`: The root dn for configuring replication. _Required._
* `root_dn_pass`: The root dn password for configuring replication. _Required._
* `role`: Replication role. Either 'supplier', 'hub', or 'consumer'. _Required._
* `suffix`: The LDAP suffix to use. _Required._
* `replication_user`: The name of the replication user. _Default: 'Replication Manager'_
* `server_host`: The host to use when calling ldapmodify. _Default: $::fqdn_
* `server_ssl_port`: The port to use when calling ldapmodify. _Default: 636_
* `user`: The owner of the created ldif file. *Default: $::ds_389::user*
* `group`: The group of the created ldif file. *Default: $::ds_389::group*
* `id`: The replica id. _Optional unless declaring a supplier._
* `purge_delay`: Time in seconds state information stored in replica entries is retained. _Default: 604800_
* `bind_dn`: The bind dn of the replication user. _Optional._
* `suppliers`: An array of supplier names to ensure. _Optional._
* `hubs`: An array of hub names to ensure. _Optional._
* `consumers`: An array of consumer names to ensure. _Optional._
* `excluded_attributes`: An array of attributes to exclude from replication. _Optional._
* `init_suppliers`: Whether to initialize replication for suppliers. _Default: false_
* `init_hubs`: Whether to initialize replication for hubs. _Default: false_
* `init_consumers`: Whether to initialize replication for consumers. _Default: false_

#### ds_389::schema
* `server_id`: The 389 ds instance name. _Required._
* `source`: The source path to use for the ldif file. _Required._
* `user`: The owner of the created ldif file. *Default: $::ds_389::user*
* `group`: The group of the created ldif file. *Default: $::ds_389::group*

#### ds_389::service
* `service_ensure`: The state the service should be in. _Default: 'running'_
* `service_enable`: Whether the service should be enabled. _Default: true_

#### ds_389::ssl
* `cert_name`: The nickname of the SSL cert to use. _Required._
* `root_dn`: The bind DN to use when calling ldapmodify. _Required._
* `root_dn_pass`: The password to use when calling ldapmodify. _Required._
* `server_host`: The host to use when calling ldapmodify. _Default: $::fqdn_
* `server_port`: The port to use when calling ldapmodify. _Default: 389_
* `server_ssl_port`: The port to use when calling ldapmodify. _Default: 636_
* `user`: The owner of the created ldif file. *Default: $::ds_389::user*
* `group`: The group of the created ldif file. *Default: $::ds_389::group*
* `minssf`: The minimum security strength for connections. _Default: 0_
* `ssl_version_min`: The minimum TLS version to allow. _Default: 'TLS1.1'_

## Limitations

This module is currently tested and working on RedHat and CentOS 6, and 7, Debian 8, and Ubuntu 14.04, and 16.04 systems.

## Development

This module was developed with [PDK](https://puppet.com/docs/pdk/1.0/index.html).

Pull requests welcome. Please see the contributing guidelines below.

### Contributing

1. Fork the repo.

2. Run the tests. We only take pull requests with passing tests, and
   it's great to know that you have a clean slate.

3. Add a test for your change. Only refactoring and documentation
   changes require no new tests. If you are adding functionality
   or fixing a bug, please add a test.

4. Make the test pass.

5. Push to your fork and submit a pull request.
