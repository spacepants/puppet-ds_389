require 'spec_helper'

describe 'ds_389::replication' do
  let(:pre_condition) do
    'include ::ds_389
    ::ds_389::ssl{ "specdirectory":
      cert_name    => "foo.example.com",
      root_dn      => "cn=Directory Manager",
      root_dn_pass => "supersecure",
    }'
  end
  let(:title) { 'specdirectory' }

  # content blocks
  let(:consumer_default) do
    'dn: cn=Replication Manager,cn=config
changetype: add
objectClass: inetorgperson
objectClass: person
objectClass: top
cn: Replication Manager
givenName: Replication
sn: Manager
userPassword: supersecret
passwordExpirationTime: 20380119031407Z
nsIdleTimeout: 0

dn: cn=replica,cn="dc=example,dc=com",cn=mapping tree,cn=config
changetype: add
objectClass: top
objectClass: nsds5replica
objectClass: extensibleObject
cn: replica
nsDS5ReplicaRoot: dc=example,dc=com
nsDS5ReplicaType: 2
nsds5flags: 0
nsds5ReplicaBindDN: cn=Replication Manager,cn=config
'
  end

  let(:consumer_custom) do
    'dn: cn=Replication Manager,cn=config
changetype: add
objectClass: inetorgperson
objectClass: person
objectClass: top
cn: Replication Manager
givenName: Replication
sn: Manager
userPassword: supersecret
passwordExpirationTime: 20380119031407Z
nsIdleTimeout: 0

dn: cn=replica,cn="dc=test,dc=org",cn=mapping tree,cn=config
changetype: add
objectClass: top
objectClass: nsds5replica
objectClass: extensibleObject
cn: replica
nsDS5ReplicaRoot: dc=test,dc=org
nsDS5ReplicaType: 2
nsds5flags: 0
nsds5ReplicaBindDN: cn=Replication Manager,cn=config
'
  end

  let(:hub_default) do
    'dn: cn=Replication Manager,cn=config
changetype: add
objectClass: inetorgperson
objectClass: person
objectClass: top
cn: Replication Manager
givenName: Replication
sn: Manager
userPassword: supersecret
passwordExpirationTime: 20380119031407Z
nsIdleTimeout: 0

dn: cn=changelog5,cn=config
changetype: add
objectClass: top
objectClass: extensibleObject
cn: changelog5
nsslapd-changelogdir: /var/lib/dirsrv/slapd-specdirectory/changelogdb

dn: cn=replica,cn="dc=example,dc=com",cn=mapping tree,cn=config
changetype: add
objectClass: top
objectClass: nsds5replica
objectClass: extensibleObject
cn: replica
nsDS5ReplicaRoot: dc=example,dc=com
nsDS5ReplicaType: 2
nsds5flags: 1
nsds5ReplicaBindDN: cn=Replication Manager,cn=config
nsds5ReplicaPurgeDelay: 604800
'
  end

  let(:hub_custom) do
    'dn: cn=Replication Manager,cn=config
changetype: add
objectClass: inetorgperson
objectClass: person
objectClass: top
cn: Replication Manager
givenName: Replication
sn: Manager
userPassword: supersecret
passwordExpirationTime: 20380119031407Z
nsIdleTimeout: 0

dn: cn=changelog5,cn=config
changetype: add
objectClass: top
objectClass: extensibleObject
cn: changelog5
nsslapd-changelogdir: /var/lib/dirsrv/slapd-specdirectory/changelogdb

dn: cn=replica,cn="dc=test,dc=org",cn=mapping tree,cn=config
changetype: add
objectClass: top
objectClass: nsds5replica
objectClass: extensibleObject
cn: replica
nsDS5ReplicaRoot: dc=test,dc=org
nsDS5ReplicaType: 2
nsds5flags: 1
nsds5ReplicaBindDN: cn=Replication Manager,cn=config
nsds5ReplicaPurgeDelay: 604800
'
  end

  let(:supplier_default) do
    'dn: cn=Replication Manager,cn=config
changetype: add
objectClass: inetorgperson
objectClass: person
objectClass: top
cn: Replication Manager
givenName: Replication
sn: Manager
userPassword: supersecret
passwordExpirationTime: 20380119031407Z
nsIdleTimeout: 0

dn: cn=changelog5,cn=config
changetype: add
objectClass: top
objectClass: extensibleObject
cn: changelog5
nsslapd-changelogdir: /var/lib/dirsrv/slapd-specdirectory/changelogdb

dn: cn=replica,cn="dc=example,dc=com",cn=mapping tree,cn=config
changetype: add
objectClass: top
objectClass: nsds5replica
objectClass: extensibleObject
cn: replica
nsDS5ReplicaRoot: dc=example,dc=com
nsDS5ReplicaType: 3
nsds5flags: 1
nsds5ReplicaBindDN: cn=Replication Manager,cn=config
nsds5ReplicaPurgeDelay: 604800
nsDS5ReplicaId: 1
'
  end

  let(:supplier_custom) do
    'dn: cn=Replication Manager,cn=config
changetype: add
objectClass: inetorgperson
objectClass: person
objectClass: top
cn: Replication Manager
givenName: Replication
sn: Manager
userPassword: supersecret
passwordExpirationTime: 20380119031407Z
nsIdleTimeout: 0

dn: cn=changelog5,cn=config
changetype: add
objectClass: top
objectClass: extensibleObject
cn: changelog5
nsslapd-changelogdir: /var/lib/dirsrv/slapd-specdirectory/changelogdb

dn: cn=replica,cn="dc=test,dc=org",cn=mapping tree,cn=config
changetype: add
objectClass: top
objectClass: nsds5replica
objectClass: extensibleObject
cn: replica
nsDS5ReplicaRoot: dc=test,dc=org
nsDS5ReplicaType: 3
nsds5flags: 1
nsds5ReplicaBindDN: cn=Replication Manager,cn=config
nsds5ReplicaPurgeDelay: 604800
nsDS5ReplicaId: 100
'
  end

  let(:consumer1_agreement) do
    'dn: cn=consumer1Agreement,cn=replica,cn="dc=example,dc=com",cn=mapping tree,cn=config
changetype: add
objectClass: top
objectClass: nsds5ReplicationAgreement
cn: consumer1Agreement
nsds5ReplicaHost: consumer1
nsds5ReplicaPort: 636
nsds5ReplicaTransportInfo: LDAP
nsds5ReplicaBindDN: cn=Replication Manager,cn=config
nsds5ReplicaBindMethod: SIMPLE
nsds5ReplicaCredentials: supersecret
nsds5ReplicaRoot: cn=Directory Manager
description: replication agreement from specdirectory to consumer1
'
  end

  let(:consumer1_agreement_custom) do
    'dn: cn=consumer1Agreement,cn=replica,cn="dc=test,dc=org",cn=mapping tree,cn=config
changetype: add
objectClass: top
objectClass: nsds5ReplicationAgreement
cn: consumer1Agreement
nsds5ReplicaHost: consumer1
nsds5ReplicaPort: 1636
nsds5ReplicaTransportInfo: SSL
nsds5ReplicaBindDN: cn=Replication Manager,cn=config
nsds5ReplicaBindMethod: SIMPLE
nsds5ReplicaCredentials: supersecret
nsds5ReplicaRoot: cn=Directory Manager
description: replication agreement from specdirectory to consumer1
'
  end

  let(:hub1_agreement) do
    'dn: cn=hub1Agreement,cn=replica,cn="dc=example,dc=com",cn=mapping tree,cn=config
changetype: add
objectClass: top
objectClass: nsds5ReplicationAgreement
cn: hub1Agreement
nsds5ReplicaHost: hub1
nsds5ReplicaPort: 636
nsds5ReplicaTransportInfo: LDAP
nsds5ReplicaBindDN: cn=Replication Manager,cn=config
nsds5ReplicaBindMethod: SIMPLE
nsds5ReplicaCredentials: supersecret
nsds5ReplicaRoot: cn=Directory Manager
description: replication agreement from specdirectory to hub1
'
  end

  let(:hub1_agreement_custom) do
    'dn: cn=hub1Agreement,cn=replica,cn="dc=test,dc=org",cn=mapping tree,cn=config
changetype: add
objectClass: top
objectClass: nsds5ReplicationAgreement
cn: hub1Agreement
nsds5ReplicaHost: hub1
nsds5ReplicaPort: 1636
nsds5ReplicaTransportInfo: SSL
nsds5ReplicaBindDN: cn=Replication Manager,cn=config
nsds5ReplicaBindMethod: SIMPLE
nsds5ReplicaCredentials: supersecret
nsds5ReplicaRoot: cn=Directory Manager
description: replication agreement from specdirectory to hub1
'
  end

  let(:supplier1_agreement) do
    'dn: cn=supplier1Agreement,cn=replica,cn="dc=example,dc=com",cn=mapping tree,cn=config
changetype: add
objectClass: top
objectClass: nsds5ReplicationAgreement
cn: supplier1Agreement
nsds5ReplicaHost: supplier1
nsds5ReplicaPort: 636
nsds5ReplicaTransportInfo: LDAP
nsds5ReplicaBindDN: cn=Replication Manager,cn=config
nsds5ReplicaBindMethod: SIMPLE
nsds5ReplicaCredentials: supersecret
nsds5ReplicaRoot: cn=Directory Manager
description: replication agreement from specdirectory to supplier1
'
  end

  let(:supplier1_agreement_custom) do
    'dn: cn=supplier1Agreement,cn=replica,cn="dc=test,dc=org",cn=mapping tree,cn=config
changetype: add
objectClass: top
objectClass: nsds5ReplicationAgreement
cn: supplier1Agreement
nsds5ReplicaHost: supplier1
nsds5ReplicaPort: 1636
nsds5ReplicaTransportInfo: SSL
nsds5ReplicaBindDN: cn=Replication Manager,cn=config
nsds5ReplicaBindMethod: SIMPLE
nsds5ReplicaCredentials: supersecret
nsds5ReplicaRoot: cn=Directory Manager
description: replication agreement from specdirectory to supplier1
'
  end

  let(:consumer1_init) do
    'dn: cn=consumer1Agreement,cn=replica,cn="dc=example,dc=com",cn=mapping tree,cn=config
changetype: modify
replace: nsds5BeginReplicaRefresh
nsds5BeginReplicaRefresh: start
'
  end

  let(:consumer1_init_custom) do
    'dn: cn=consumer1Agreement,cn=replica,cn="dc=test,dc=org",cn=mapping tree,cn=config
changetype: modify
replace: nsds5BeginReplicaRefresh
nsds5BeginReplicaRefresh: start
'
  end

  let(:hub1_init) do
    'dn: cn=hub1Agreement,cn=replica,cn="dc=example,dc=com",cn=mapping tree,cn=config
changetype: modify
replace: nsds5BeginReplicaRefresh
nsds5BeginReplicaRefresh: start
'
  end

  let(:hub1_init_custom) do
    'dn: cn=hub1Agreement,cn=replica,cn="dc=test,dc=org",cn=mapping tree,cn=config
changetype: modify
replace: nsds5BeginReplicaRefresh
nsds5BeginReplicaRefresh: start
'
  end

  let(:supplier1_init) do
    'dn: cn=supplier1Agreement,cn=replica,cn="dc=example,dc=com",cn=mapping tree,cn=config
changetype: modify
replace: nsds5BeginReplicaRefresh
nsds5BeginReplicaRefresh: start
'
  end

  let(:supplier1_init_custom) do
    'dn: cn=supplier1Agreement,cn=replica,cn="dc=test,dc=org",cn=mapping tree,cn=config
changetype: modify
replace: nsds5BeginReplicaRefresh
nsds5BeginReplicaRefresh: start
'
  end

  on_supported_os(facterversion: '2.4').each do |os, os_facts|
    context "on #{os}" do
      let(:facts) do
        os_facts.merge(
          fqdn: 'foo.example.com',
        )
      end

      context 'when setting up a consumer' do
        context 'with required parameters' do
          let(:params) do
            {
              replication_pass: 'supersecret',
              root_dn: 'cn=Directory Manager',
              root_dn_pass: 'supersecure',
              role: 'consumer',
              suffix: 'dc=example,dc=com',
            }
          end

          it { is_expected.to compile }

          it {
            is_expected.to contain_file('/etc/dirsrv/slapd-specdirectory/replication.ldif').with(
              ensure: 'file',
              mode: '0440',
              owner: 'dirsrv',
              group: 'dirsrv',
              content: consumer_default,
            )
          }
          it {
            is_expected.to contain_exec('Set up replication: specdirectory').with(
              command: 'ldapmodify -h foo.example.com -p 389 -x -D "cn=Directory Manager" -w supersecure -f /etc/dirsrv/slapd-specdirectory/replication.ldif ; touch /etc/dirsrv/slapd-specdirectory/replication.done', # rubocop:disable LineLength
              path: '/usr/bin:/bin',
              creates: '/etc/dirsrv/slapd-specdirectory/replication.done',
            ).that_requires('File[/etc/dirsrv/slapd-specdirectory/replication.ldif]')
          }

          it { is_expected.to contain_anchor('specdirectory_replication_suppliers').that_requires('Exec[Set up replication: specdirectory]') }
          it { is_expected.to contain_anchor('specdirectory_replication_hubs').that_requires('Anchor[specdirectory_replication_suppliers]') }
          it { is_expected.to contain_anchor('specdirectory_replication_consumers').that_requires('Anchor[specdirectory_replication_hubs]') }
        end

        context 'with parameter overrides' do
          let(:params) do
            {
              replication_pass: 'supersecret',
              root_dn: 'cn=Directory Manager',
              root_dn_pass: 'supersecure',
              role: 'consumer',
              suffix: 'dc=test,dc=org',
              server_host: 'ldap.test.org',
              server_port: 1389,
              replica_port: 1636,
              replica_transport: 'SSL',
              user: 'custom_user',
              group: 'custom_group',
            }
          end

          it { is_expected.to compile }

          it {
            is_expected.to contain_file('/etc/dirsrv/slapd-specdirectory/replication.ldif').with(
              ensure: 'file',
              mode: '0440',
              owner: 'custom_user',
              group: 'custom_group',
              content: consumer_custom,
            )
          }
          it {
            is_expected.to contain_exec('Set up replication: specdirectory').with(
              command: 'ldapmodify -h ldap.test.org -p 1389 -x -D "cn=Directory Manager" -w supersecure -f /etc/dirsrv/slapd-specdirectory/replication.ldif ; touch /etc/dirsrv/slapd-specdirectory/replication.done', # rubocop:disable LineLength
              path: '/usr/bin:/bin',
              creates: '/etc/dirsrv/slapd-specdirectory/replication.done',
            ).that_requires('File[/etc/dirsrv/slapd-specdirectory/replication.ldif]')
          }
        end
      end

      context 'when setting up a hub' do
        context 'with required parameters' do
          let(:params) do
            {
              replication_pass: 'supersecret',
              root_dn: 'cn=Directory Manager',
              root_dn_pass: 'supersecure',
              role: 'hub',
              suffix: 'dc=example,dc=com',
              consumers: %w[consumer1 specdirectory],
            }
          end

          it { is_expected.to compile }

          it {
            is_expected.to contain_file('/etc/dirsrv/slapd-specdirectory/replication.ldif').with(
              ensure: 'file',
              mode: '0440',
              owner: 'dirsrv',
              group: 'dirsrv',
              content: hub_default,
            )
          }
          it {
            is_expected.to contain_exec('Set up replication: specdirectory').with(
              command: 'ldapmodify -h foo.example.com -p 389 -x -D "cn=Directory Manager" -w supersecure -f /etc/dirsrv/slapd-specdirectory/replication.ldif ; touch /etc/dirsrv/slapd-specdirectory/replication.done', # rubocop:disable LineLength
              path: '/usr/bin:/bin',
              creates: '/etc/dirsrv/slapd-specdirectory/replication.done',
            ).that_requires('File[/etc/dirsrv/slapd-specdirectory/replication.ldif]')
          }

          it { is_expected.not_to contain_file('/etc/dirsrv/slapd-specdirectory/consumer_specdirectory.ldif') }
          it { is_expected.not_to contain_exec('Create replication agreement for consumer specdirectory: specdirectory') }

          it {
            is_expected.to contain_file('/etc/dirsrv/slapd-specdirectory/consumer_consumer1.ldif').with(
              ensure: 'file',
              mode: '0440',
              owner: 'dirsrv',
              group: 'dirsrv',
              content: consumer1_agreement,
            )
          }
          it {
            is_expected.to contain_exec('Create replication agreement for consumer consumer1: specdirectory').with(
              command: 'ldapmodify -h foo.example.com -p 389 -x -D "cn=Directory Manager" -w supersecure -f /etc/dirsrv/slapd-specdirectory/consumer_consumer1.ldif ; touch /etc/dirsrv/slapd-specdirectory/consumer_consumer1.done', # rubocop:disable LineLength
              path: '/usr/bin:/bin',
              creates: '/etc/dirsrv/slapd-specdirectory/consumer_consumer1.done',
            ).that_requires(
              [
                'File[/etc/dirsrv/slapd-specdirectory/consumer_consumer1.ldif]',
                'Exec[Set up replication: specdirectory]',
              ],
            )
          }

          it { is_expected.not_to contain_file('/etc/dirsrv/slapd-specdirectory/consumer_consumer1_init.ldif') }
          it { is_expected.not_to contain_exec('Initialize consumer consumer1: specdirectory') }

          context 'when initializing consumers' do
            let(:params) do
              {
                replication_pass: 'supersecret',
                root_dn: 'cn=Directory Manager',
                root_dn_pass: 'supersecure',
                role: 'hub',
                suffix: 'dc=example,dc=com',
                consumers: ['consumer1'],
                init_consumers: true,
              }
            end

            it { is_expected.not_to contain_file('/etc/dirsrv/slapd-specdirectory/consumer_specdirectory_init.ldif') }
            it { is_expected.not_to contain_exec('Initialize consumer specdirectory: specdirectory') }

            it {
              is_expected.to contain_file('/etc/dirsrv/slapd-specdirectory/consumer_consumer1_init.ldif').with(
                ensure: 'file',
                mode: '0440',
                owner: 'dirsrv',
                group: 'dirsrv',
                content: consumer1_init,
              )
            }
            it {
              is_expected.to contain_exec('Initialize consumer consumer1: specdirectory').with(
                command: 'ldapmodify -h foo.example.com -p 389 -x -D "cn=Directory Manager" -w supersecure -f /etc/dirsrv/slapd-specdirectory/consumer_consumer1_init.ldif ; touch /etc/dirsrv/slapd-specdirectory/consumer_consumer1_init.done', # rubocop:disable LineLength
                path: '/usr/bin:/bin',
                creates: '/etc/dirsrv/slapd-specdirectory/consumer_consumer1_init.done',
              ).that_requires(
                [
                  'File[/etc/dirsrv/slapd-specdirectory/consumer_consumer1_init.ldif]',
                  'Exec[Set up replication: specdirectory]',
                ],
              )
            }
          end
        end

        context 'with parameter overrides' do
          let(:params) do
            {
              replication_pass: 'supersecret',
              root_dn: 'cn=Directory Manager',
              root_dn_pass: 'supersecure',
              role: 'hub',
              suffix: 'dc=test,dc=org',
              server_host: 'ldap.test.org',
              server_port: 1389,
              replica_port: 1636,
              replica_transport: 'SSL',
              user: 'custom_user',
              group: 'custom_group',
              consumers: %w[consumer1 specdirectory],
            }
          end

          it { is_expected.to compile }

          it {
            is_expected.to contain_file('/etc/dirsrv/slapd-specdirectory/replication.ldif').with(
              ensure: 'file',
              mode: '0440',
              owner: 'custom_user',
              group: 'custom_group',
              content: hub_custom,
            )
          }
          it {
            is_expected.to contain_exec('Set up replication: specdirectory').with(
              command: 'ldapmodify -h ldap.test.org -p 1389 -x -D "cn=Directory Manager" -w supersecure -f /etc/dirsrv/slapd-specdirectory/replication.ldif ; touch /etc/dirsrv/slapd-specdirectory/replication.done', # rubocop:disable LineLength
              path: '/usr/bin:/bin',
              creates: '/etc/dirsrv/slapd-specdirectory/replication.done',
            ).that_requires('File[/etc/dirsrv/slapd-specdirectory/replication.ldif]')
          }

          it { is_expected.not_to contain_file('/etc/dirsrv/slapd-specdirectory/consumer_specdirectory.ldif') }
          it { is_expected.not_to contain_exec('Create replication agreement for consumer specdirectory: specdirectory') }

          it {
            is_expected.to contain_file('/etc/dirsrv/slapd-specdirectory/consumer_consumer1.ldif').with(
              ensure: 'file',
              mode: '0440',
              owner: 'custom_user',
              group: 'custom_group',
              content: consumer1_agreement_custom,
            )
          }
          it {
            is_expected.to contain_exec('Create replication agreement for consumer consumer1: specdirectory').with(
              command: 'ldapmodify -h ldap.test.org -p 1389 -x -D "cn=Directory Manager" -w supersecure -f /etc/dirsrv/slapd-specdirectory/consumer_consumer1.ldif ; touch /etc/dirsrv/slapd-specdirectory/consumer_consumer1.done', # rubocop:disable LineLength
              path: '/usr/bin:/bin',
              creates: '/etc/dirsrv/slapd-specdirectory/consumer_consumer1.done',
            ).that_requires('File[/etc/dirsrv/slapd-specdirectory/consumer_consumer1.ldif]')
          }

          it { is_expected.not_to contain_file('/etc/dirsrv/slapd-specdirectory/consumer_consumer1_init.ldif') }
          it { is_expected.not_to contain_exec('Initialize consumer consumer1: specdirectory') }

          context 'when initializing consumers' do
            let(:params) do
              {
                replication_pass: 'supersecret',
                root_dn: 'cn=Directory Manager',
                root_dn_pass: 'supersecure',
                role: 'hub',
                suffix: 'dc=test,dc=org',
                server_host: 'ldap.test.org',
                server_port: 1389,
                replica_port: 1636,
                replica_transport: 'SSL',
                user: 'custom_user',
                group: 'custom_group',
                consumers: ['consumer1'],
                init_consumers: true,
              }
            end

            it { is_expected.not_to contain_file('/etc/dirsrv/slapd-specdirectory/consumer_specdirectory_init.ldif') }
            it { is_expected.not_to contain_exec('Initialize consumer specdirectory: specdirectory') }

            it {
              is_expected.to contain_file('/etc/dirsrv/slapd-specdirectory/consumer_consumer1_init.ldif').with(
                ensure: 'file',
                mode: '0440',
                owner: 'custom_user',
                group: 'custom_group',
                content: consumer1_init_custom,
              )
            }
            it {
              is_expected.to contain_exec('Initialize consumer consumer1: specdirectory').with(
                command: 'ldapmodify -h ldap.test.org -p 1389 -x -D "cn=Directory Manager" -w supersecure -f /etc/dirsrv/slapd-specdirectory/consumer_consumer1_init.ldif ; touch /etc/dirsrv/slapd-specdirectory/consumer_consumer1_init.done', # rubocop:disable LineLength
                path: '/usr/bin:/bin',
                creates: '/etc/dirsrv/slapd-specdirectory/consumer_consumer1_init.done',
              ).that_requires(
                [
                  'File[/etc/dirsrv/slapd-specdirectory/consumer_consumer1_init.ldif]',
                  'Exec[Set up replication: specdirectory]',
                ],
              )
            }
          end
        end
      end

      context 'when setting up a supplier' do
        context 'with required parameters' do
          let(:params) do
            {
              replication_pass: 'supersecret',
              root_dn: 'cn=Directory Manager',
              root_dn_pass: 'supersecure',
              role: 'supplier',
              suffix: 'dc=example,dc=com',
              id: 1,
              suppliers: %w[supplier1 specdirectory],
              hubs: %w[hub1 specdirectory],
              consumers: %w[consumer1 specdirectory],
            }
          end

          it { is_expected.to compile }

          it {
            is_expected.to contain_file('/etc/dirsrv/slapd-specdirectory/replication.ldif').with(
              ensure: 'file',
              mode: '0440',
              owner: 'dirsrv',
              group: 'dirsrv',
              content: supplier_default,
            )
          }
          it {
            is_expected.to contain_exec('Set up replication: specdirectory').with(
              command: 'ldapmodify -h foo.example.com -p 389 -x -D "cn=Directory Manager" -w supersecure -f /etc/dirsrv/slapd-specdirectory/replication.ldif ; touch /etc/dirsrv/slapd-specdirectory/replication.done', # rubocop:disable LineLength
              path: '/usr/bin:/bin',
              creates: '/etc/dirsrv/slapd-specdirectory/replication.done',
            ).that_requires('File[/etc/dirsrv/slapd-specdirectory/replication.ldif]')
          }

          it { is_expected.not_to contain_file('/etc/dirsrv/slapd-specdirectory/supplier_specdirectory.ldif') }
          it { is_expected.not_to contain_exec('Create replication agreement for supplier specdirectory: specdirectory') }
          it { is_expected.not_to contain_file('/etc/dirsrv/slapd-specdirectory/hub_specdirectory.ldif') }
          it { is_expected.not_to contain_exec('Create replication agreement for hub specdirectory: specdirectory') }
          it { is_expected.not_to contain_file('/etc/dirsrv/slapd-specdirectory/consumer_specdirectory.ldif') }
          it { is_expected.not_to contain_exec('Create replication agreement for consumer specdirectory: specdirectory') }

          it {
            is_expected.to contain_file('/etc/dirsrv/slapd-specdirectory/supplier_supplier1.ldif').with(
              ensure: 'file',
              mode: '0440',
              owner: 'dirsrv',
              group: 'dirsrv',
              content: supplier1_agreement,
            )
          }
          it {
            is_expected.to contain_exec('Create replication agreement for supplier supplier1: specdirectory').with(
              command: 'ldapmodify -h foo.example.com -p 389 -x -D "cn=Directory Manager" -w supersecure -f /etc/dirsrv/slapd-specdirectory/supplier_supplier1.ldif ; touch /etc/dirsrv/slapd-specdirectory/supplier_supplier1.done', # rubocop:disable LineLength
              path: '/usr/bin:/bin',
              creates: '/etc/dirsrv/slapd-specdirectory/supplier_supplier1.done',
            ).that_requires(
              [
                'File[/etc/dirsrv/slapd-specdirectory/supplier_supplier1.ldif]',
                'Exec[Set up replication: specdirectory]',
              ],
            )
          }

          it {
            is_expected.to contain_file('/etc/dirsrv/slapd-specdirectory/hub_hub1.ldif').with(
              ensure: 'file',
              mode: '0440',
              owner: 'dirsrv',
              group: 'dirsrv',
              content: hub1_agreement,
            )
          }
          it {
            is_expected.to contain_exec('Create replication agreement for hub hub1: specdirectory').with(
              command: 'ldapmodify -h foo.example.com -p 389 -x -D "cn=Directory Manager" -w supersecure -f /etc/dirsrv/slapd-specdirectory/hub_hub1.ldif ; touch /etc/dirsrv/slapd-specdirectory/hub_hub1.done', # rubocop:disable LineLength
              path: '/usr/bin:/bin',
              creates: '/etc/dirsrv/slapd-specdirectory/hub_hub1.done',
            ).that_requires(
              [
                'File[/etc/dirsrv/slapd-specdirectory/hub_hub1.ldif]',
                'Exec[Set up replication: specdirectory]',
              ],
            )
          }

          it {
            is_expected.to contain_file('/etc/dirsrv/slapd-specdirectory/consumer_consumer1.ldif').with(
              ensure: 'file',
              mode: '0440',
              owner: 'dirsrv',
              group: 'dirsrv',
              content: consumer1_agreement,
            )
          }
          it {
            is_expected.to contain_exec('Create replication agreement for consumer consumer1: specdirectory').with(
              command: 'ldapmodify -h foo.example.com -p 389 -x -D "cn=Directory Manager" -w supersecure -f /etc/dirsrv/slapd-specdirectory/consumer_consumer1.ldif ; touch /etc/dirsrv/slapd-specdirectory/consumer_consumer1.done', # rubocop:disable LineLength
              path: '/usr/bin:/bin',
              creates: '/etc/dirsrv/slapd-specdirectory/consumer_consumer1.done',
            ).that_requires(
              [
                'File[/etc/dirsrv/slapd-specdirectory/consumer_consumer1.ldif]',
                'Exec[Set up replication: specdirectory]',
              ],
            )
          }

          it { is_expected.not_to contain_file('/etc/dirsrv/slapd-specdirectory/supplier_supplier1_init.ldif') }
          it { is_expected.not_to contain_exec('Initialize supplier supplier1: specdirectory') }
          it { is_expected.not_to contain_file('/etc/dirsrv/slapd-specdirectory/hub_hub1_init.ldif') }
          it { is_expected.not_to contain_exec('Initialize hub hub1: specdirectory') }
          it { is_expected.not_to contain_file('/etc/dirsrv/slapd-specdirectory/consumer_consumer1_init.ldif') }
          it { is_expected.not_to contain_exec('Initialize consumer consumer1: specdirectory') }

          context 'when initializing suppliers' do
            let(:params) do
              {
                replication_pass: 'supersecret',
                root_dn: 'cn=Directory Manager',
                root_dn_pass: 'supersecure',
                role: 'supplier',
                suffix: 'dc=example,dc=com',
                id: 1,
                suppliers: %w[supplier1 specdirectory],
                hubs: %w[hub1 specdirectory],
                consumers: %w[consumer1 specdirectory],
                init_suppliers: true,
              }
            end

            it { is_expected.not_to contain_file('/etc/dirsrv/slapd-specdirectory/supplier_specdirectory_init.ldif') }
            it { is_expected.not_to contain_exec('Initialize supplier specdirectory: specdirectory') }
            it { is_expected.not_to contain_file('/etc/dirsrv/slapd-specdirectory/hub_specdirectory_init.ldif') }
            it { is_expected.not_to contain_exec('Initialize hub specdirectory: specdirectory') }
            it { is_expected.not_to contain_file('/etc/dirsrv/slapd-specdirectory/consumer_specdirectory_init.ldif') }
            it { is_expected.not_to contain_exec('Initialize consumer specdirectory: specdirectory') }

            it { is_expected.not_to contain_file('/etc/dirsrv/slapd-specdirectory/hub_hub1_init.ldif') }
            it { is_expected.not_to contain_exec('Initialize hub hub1: specdirectory') }
            it { is_expected.not_to contain_file('/etc/dirsrv/slapd-specdirectory/consumer_consumer1_init.ldif') }
            it { is_expected.not_to contain_exec('Initialize consumer consumer1: specdirectory') }

            it {
              is_expected.to contain_file('/etc/dirsrv/slapd-specdirectory/supplier_supplier1_init.ldif').with(
                ensure: 'file',
                mode: '0440',
                owner: 'dirsrv',
                group: 'dirsrv',
                content: supplier1_init,
              )
            }
            it {
              is_expected.to contain_exec('Initialize supplier supplier1: specdirectory').with(
                command: 'ldapmodify -h foo.example.com -p 389 -x -D "cn=Directory Manager" -w supersecure -f /etc/dirsrv/slapd-specdirectory/supplier_supplier1_init.ldif ; touch /etc/dirsrv/slapd-specdirectory/supplier_supplier1_init.done', # rubocop:disable LineLength
                path: '/usr/bin:/bin',
                creates: '/etc/dirsrv/slapd-specdirectory/supplier_supplier1_init.done',
              ).that_requires(
                [
                  'File[/etc/dirsrv/slapd-specdirectory/supplier_supplier1_init.ldif]',
                  'Exec[Set up replication: specdirectory]',
                ],
              )
            }
          end

          context 'when initializing hubs' do
            let(:params) do
              {
                replication_pass: 'supersecret',
                root_dn: 'cn=Directory Manager',
                root_dn_pass: 'supersecure',
                role: 'supplier',
                suffix: 'dc=example,dc=com',
                id: 1,
                suppliers: %w[supplier1 specdirectory],
                hubs: %w[hub1 specdirectory],
                consumers: %w[consumer1 specdirectory],
                init_hubs: true,
              }
            end

            it { is_expected.not_to contain_file('/etc/dirsrv/slapd-specdirectory/supplier_specdirectory_init.ldif') }
            it { is_expected.not_to contain_exec('Initialize supplier specdirectory: specdirectory') }
            it { is_expected.not_to contain_file('/etc/dirsrv/slapd-specdirectory/hub_specdirectory_init.ldif') }
            it { is_expected.not_to contain_exec('Initialize hub specdirectory: specdirectory') }
            it { is_expected.not_to contain_file('/etc/dirsrv/slapd-specdirectory/consumer_specdirectory_init.ldif') }
            it { is_expected.not_to contain_exec('Initialize consumer specdirectory: specdirectory') }

            it { is_expected.not_to contain_file('/etc/dirsrv/slapd-specdirectory/supplier_supplier1_init.ldif') }
            it { is_expected.not_to contain_exec('Initialize supplier supplier1: specdirectory') }
            it { is_expected.not_to contain_file('/etc/dirsrv/slapd-specdirectory/consumer_consumer1_init.ldif') }
            it { is_expected.not_to contain_exec('Initialize consumer consumer1: specdirectory') }

            it {
              is_expected.to contain_file('/etc/dirsrv/slapd-specdirectory/hub_hub1_init.ldif').with(
                ensure: 'file',
                mode: '0440',
                owner: 'dirsrv',
                group: 'dirsrv',
                content: hub1_init,
              )
            }
            it {
              is_expected.to contain_exec('Initialize hub hub1: specdirectory').with(
                command: 'ldapmodify -h foo.example.com -p 389 -x -D "cn=Directory Manager" -w supersecure -f /etc/dirsrv/slapd-specdirectory/hub_hub1_init.ldif ; touch /etc/dirsrv/slapd-specdirectory/hub_hub1_init.done', # rubocop:disable LineLength
                path: '/usr/bin:/bin',
                creates: '/etc/dirsrv/slapd-specdirectory/hub_hub1_init.done',
              ).that_requires(
                [
                  'File[/etc/dirsrv/slapd-specdirectory/hub_hub1_init.ldif]',
                  'Exec[Set up replication: specdirectory]',
                ],
              )
            }
          end

          context 'when initializing consumers' do
            let(:params) do
              {
                replication_pass: 'supersecret',
                root_dn: 'cn=Directory Manager',
                root_dn_pass: 'supersecure',
                role: 'supplier',
                suffix: 'dc=example,dc=com',
                id: 1,
                suppliers: %w[supplier1 specdirectory],
                hubs: %w[hub1 specdirectory],
                consumers: %w[consumer1 specdirectory],
                init_consumers: true,
              }
            end

            it { is_expected.not_to contain_file('/etc/dirsrv/slapd-specdirectory/supplier_specdirectory_init.ldif') }
            it { is_expected.not_to contain_exec('Initialize supplier specdirectory: specdirectory') }
            it { is_expected.not_to contain_file('/etc/dirsrv/slapd-specdirectory/hub_specdirectory_init.ldif') }
            it { is_expected.not_to contain_exec('Initialize hub specdirectory: specdirectory') }
            it { is_expected.not_to contain_file('/etc/dirsrv/slapd-specdirectory/consumer_specdirectory_init.ldif') }
            it { is_expected.not_to contain_exec('Initialize consumer specdirectory: specdirectory') }

            it { is_expected.not_to contain_file('/etc/dirsrv/slapd-specdirectory/supplier_supplier1_init.ldif') }
            it { is_expected.not_to contain_exec('Initialize supplier supplier1: specdirectory') }
            it { is_expected.not_to contain_file('/etc/dirsrv/slapd-specdirectory/hub_hub1_init.ldif') }
            it { is_expected.not_to contain_exec('Initialize hub hub1: specdirectory') }

            it {
              is_expected.to contain_file('/etc/dirsrv/slapd-specdirectory/consumer_consumer1_init.ldif').with(
                ensure: 'file',
                mode: '0440',
                owner: 'dirsrv',
                group: 'dirsrv',
                content: consumer1_init,
              )
            }
            it {
              is_expected.to contain_exec('Initialize consumer consumer1: specdirectory').with(
                command: 'ldapmodify -h foo.example.com -p 389 -x -D "cn=Directory Manager" -w supersecure -f /etc/dirsrv/slapd-specdirectory/consumer_consumer1_init.ldif ; touch /etc/dirsrv/slapd-specdirectory/consumer_consumer1_init.done', # rubocop:disable LineLength
                path: '/usr/bin:/bin',
                creates: '/etc/dirsrv/slapd-specdirectory/consumer_consumer1_init.done',
              ).that_requires(
                [
                  'File[/etc/dirsrv/slapd-specdirectory/consumer_consumer1_init.ldif]',
                  'Exec[Set up replication: specdirectory]',
                ],
              )
            }
          end
        end

        context 'with parameter overrides' do
          let(:params) do
            {
              replication_pass: 'supersecret',
              root_dn: 'cn=Directory Manager',
              root_dn_pass: 'supersecure',
              role: 'supplier',
              suffix: 'dc=test,dc=org',
              server_host: 'ldap.test.org',
              server_port: 1389,
              replica_port: 1636,
              replica_transport: 'SSL',
              user: 'custom_user',
              group: 'custom_group',
              id: 100,
              suppliers: %w[supplier1 specdirectory],
              hubs: %w[hub1 specdirectory],
              consumers: %w[consumer1 specdirectory],
            }
          end

          it { is_expected.to compile }

          it {
            is_expected.to contain_file('/etc/dirsrv/slapd-specdirectory/replication.ldif').with(
              ensure: 'file',
              mode: '0440',
              owner: 'custom_user',
              group: 'custom_group',
              content: supplier_custom,
            )
          }
          it {
            is_expected.to contain_exec('Set up replication: specdirectory').with(
              command: 'ldapmodify -h ldap.test.org -p 1389 -x -D "cn=Directory Manager" -w supersecure -f /etc/dirsrv/slapd-specdirectory/replication.ldif ; touch /etc/dirsrv/slapd-specdirectory/replication.done', # rubocop:disable LineLength
              path: '/usr/bin:/bin',
              creates: '/etc/dirsrv/slapd-specdirectory/replication.done',
            ).that_requires('File[/etc/dirsrv/slapd-specdirectory/replication.ldif]')
          }

          it { is_expected.not_to contain_file('/etc/dirsrv/slapd-specdirectory/supplier_specdirectory.ldif') }
          it { is_expected.not_to contain_exec('Create replication agreement for supplier specdirectory: specdirectory') }

          it {
            is_expected.to contain_file('/etc/dirsrv/slapd-specdirectory/supplier_supplier1.ldif').with(
              ensure: 'file',
              mode: '0440',
              owner: 'custom_user',
              group: 'custom_group',
              content: supplier1_agreement_custom,
            )
          }
          it {
            is_expected.to contain_exec('Create replication agreement for supplier supplier1: specdirectory').with(
              command: 'ldapmodify -h ldap.test.org -p 1389 -x -D "cn=Directory Manager" -w supersecure -f /etc/dirsrv/slapd-specdirectory/supplier_supplier1.ldif ; touch /etc/dirsrv/slapd-specdirectory/supplier_supplier1.done', # rubocop:disable LineLength
              path: '/usr/bin:/bin',
              creates: '/etc/dirsrv/slapd-specdirectory/supplier_supplier1.done',
            ).that_requires('File[/etc/dirsrv/slapd-specdirectory/supplier_supplier1.ldif]')
          }

          it {
            is_expected.to contain_file('/etc/dirsrv/slapd-specdirectory/hub_hub1.ldif').with(
              ensure: 'file',
              mode: '0440',
              owner: 'custom_user',
              group: 'custom_group',
              content: hub1_agreement_custom,
            )
          }
          it {
            is_expected.to contain_exec('Create replication agreement for hub hub1: specdirectory').with(
              command: 'ldapmodify -h ldap.test.org -p 1389 -x -D "cn=Directory Manager" -w supersecure -f /etc/dirsrv/slapd-specdirectory/hub_hub1.ldif ; touch /etc/dirsrv/slapd-specdirectory/hub_hub1.done', # rubocop:disable LineLength
              path: '/usr/bin:/bin',
              creates: '/etc/dirsrv/slapd-specdirectory/hub_hub1.done',
            ).that_requires(
              [
                'File[/etc/dirsrv/slapd-specdirectory/hub_hub1.ldif]',
                'Exec[Set up replication: specdirectory]',
              ],
            )
          }

          it {
            is_expected.to contain_file('/etc/dirsrv/slapd-specdirectory/consumer_consumer1.ldif').with(
              ensure: 'file',
              mode: '0440',
              owner: 'custom_user',
              group: 'custom_group',
              content: consumer1_agreement_custom,
            )
          }
          it {
            is_expected.to contain_exec('Create replication agreement for consumer consumer1: specdirectory').with(
              command: 'ldapmodify -h ldap.test.org -p 1389 -x -D "cn=Directory Manager" -w supersecure -f /etc/dirsrv/slapd-specdirectory/consumer_consumer1.ldif ; touch /etc/dirsrv/slapd-specdirectory/consumer_consumer1.done', # rubocop:disable LineLength
              path: '/usr/bin:/bin',
              creates: '/etc/dirsrv/slapd-specdirectory/consumer_consumer1.done',
            ).that_requires(
              [
                'File[/etc/dirsrv/slapd-specdirectory/consumer_consumer1.ldif]',
                'Exec[Set up replication: specdirectory]',
              ],
            )
          }

          it { is_expected.not_to contain_file('/etc/dirsrv/slapd-specdirectory/supplier_supplier1_init.ldif') }
          it { is_expected.not_to contain_exec('Initialize supplier supplier1: specdirectory') }
          it { is_expected.not_to contain_file('/etc/dirsrv/slapd-specdirectory/hub_hub1_init.ldif') }
          it { is_expected.not_to contain_exec('Initialize hub hub1: specdirectory') }
          it { is_expected.not_to contain_file('/etc/dirsrv/slapd-specdirectory/consumer_consumer1_init.ldif') }
          it { is_expected.not_to contain_exec('Initialize consumer consumer1: specdirectory') }
        end

        context 'when initializing suppliers' do
          let(:params) do
            {
              replication_pass: 'supersecret',
              root_dn: 'cn=Directory Manager',
              root_dn_pass: 'supersecure',
              role: 'supplier',
              suffix: 'dc=test,dc=org',
              server_host: 'ldap.test.org',
              server_port: 1389,
              replica_port: 1636,
              replica_transport: 'SSL',
              user: 'custom_user',
              group: 'custom_group',
              id: 100,
              suppliers: %w[supplier1 specdirectory],
              hubs: %w[hub1 specdirectory],
              consumers: %w[consumer1 specdirectory],
              init_suppliers: true,
            }
          end

          it { is_expected.not_to contain_file('/etc/dirsrv/slapd-specdirectory/supplier_specdirectory_init.ldif') }
          it { is_expected.not_to contain_exec('Initialize supplier specdirectory: specdirectory') }
          it { is_expected.not_to contain_file('/etc/dirsrv/slapd-specdirectory/hub_specdirectory_init.ldif') }
          it { is_expected.not_to contain_exec('Initialize hub specdirectory: specdirectory') }
          it { is_expected.not_to contain_file('/etc/dirsrv/slapd-specdirectory/consumer_specdirectory_init.ldif') }
          it { is_expected.not_to contain_exec('Initialize consumer specdirectory: specdirectory') }

          it { is_expected.not_to contain_file('/etc/dirsrv/slapd-specdirectory/hub_hub1_init.ldif') }
          it { is_expected.not_to contain_exec('Initialize hub hub1: specdirectory') }
          it { is_expected.not_to contain_file('/etc/dirsrv/slapd-specdirectory/consumer_consumer1_init.ldif') }
          it { is_expected.not_to contain_exec('Initialize consumer consumer1: specdirectory') }

          it {
            is_expected.to contain_file('/etc/dirsrv/slapd-specdirectory/supplier_supplier1_init.ldif').with(
              ensure: 'file',
              mode: '0440',
              owner: 'custom_user',
              group: 'custom_group',
              content: supplier1_init_custom,
            )
          }
          it {
            is_expected.to contain_exec('Initialize supplier supplier1: specdirectory').with(
              command: 'ldapmodify -h ldap.test.org -p 1389 -x -D "cn=Directory Manager" -w supersecure -f /etc/dirsrv/slapd-specdirectory/supplier_supplier1_init.ldif ; touch /etc/dirsrv/slapd-specdirectory/supplier_supplier1_init.done', # rubocop:disable LineLength
              path: '/usr/bin:/bin',
              creates: '/etc/dirsrv/slapd-specdirectory/supplier_supplier1_init.done',
            ).that_requires(
              [
                'File[/etc/dirsrv/slapd-specdirectory/supplier_supplier1_init.ldif]',
                'Exec[Set up replication: specdirectory]',
              ],
            )
          }
        end

        context 'when initializing hubs' do
          let(:params) do
            {
              replication_pass: 'supersecret',
              root_dn: 'cn=Directory Manager',
              root_dn_pass: 'supersecure',
              role: 'supplier',
              suffix: 'dc=test,dc=org',
              server_host: 'ldap.test.org',
              server_port: 1389,
              replica_port: 1636,
              replica_transport: 'SSL',
              user: 'custom_user',
              group: 'custom_group',
              id: 100,
              suppliers: %w[supplier1 specdirectory],
              hubs: %w[hub1 specdirectory],
              consumers: %w[consumer1 specdirectory],
              init_hubs: true,
            }
          end

          it { is_expected.not_to contain_file('/etc/dirsrv/slapd-specdirectory/supplier_specdirectory_init.ldif') }
          it { is_expected.not_to contain_exec('Initialize supplier specdirectory: specdirectory') }
          it { is_expected.not_to contain_file('/etc/dirsrv/slapd-specdirectory/hub_specdirectory_init.ldif') }
          it { is_expected.not_to contain_exec('Initialize hub specdirectory: specdirectory') }
          it { is_expected.not_to contain_file('/etc/dirsrv/slapd-specdirectory/consumer_specdirectory_init.ldif') }
          it { is_expected.not_to contain_exec('Initialize consumer specdirectory: specdirectory') }

          it { is_expected.not_to contain_file('/etc/dirsrv/slapd-specdirectory/supplier_supplier1_init.ldif') }
          it { is_expected.not_to contain_exec('Initialize supplier supplier1: specdirectory') }
          it { is_expected.not_to contain_file('/etc/dirsrv/slapd-specdirectory/consumer_consumer1_init.ldif') }
          it { is_expected.not_to contain_exec('Initialize consumer consumer1: specdirectory') }

          it {
            is_expected.to contain_file('/etc/dirsrv/slapd-specdirectory/hub_hub1_init.ldif').with(
              ensure: 'file',
              mode: '0440',
              owner: 'custom_user',
              group: 'custom_group',
              content: hub1_init_custom,
            )
          }
          it {
            is_expected.to contain_exec('Initialize hub hub1: specdirectory').with(
              command: 'ldapmodify -h ldap.test.org -p 1389 -x -D "cn=Directory Manager" -w supersecure -f /etc/dirsrv/slapd-specdirectory/hub_hub1_init.ldif ; touch /etc/dirsrv/slapd-specdirectory/hub_hub1_init.done', # rubocop:disable LineLength
              path: '/usr/bin:/bin',
              creates: '/etc/dirsrv/slapd-specdirectory/hub_hub1_init.done',
            ).that_requires(
              [
                'File[/etc/dirsrv/slapd-specdirectory/hub_hub1_init.ldif]',
                'Exec[Set up replication: specdirectory]',
              ],
            )
          }
        end

        context 'when initializing consumers' do
          let(:params) do
            {
              replication_pass: 'supersecret',
              root_dn: 'cn=Directory Manager',
              root_dn_pass: 'supersecure',
              role: 'supplier',
              suffix: 'dc=test,dc=org',
              server_host: 'ldap.test.org',
              server_port: 1389,
              replica_port: 1636,
              replica_transport: 'SSL',
              user: 'custom_user',
              group: 'custom_group',
              id: 100,
              suppliers: %w[supplier1 specdirectory],
              hubs: %w[hub1 specdirectory],
              consumers: %w[consumer1 specdirectory],
              init_consumers: true,
            }
          end

          it { is_expected.not_to contain_file('/etc/dirsrv/slapd-specdirectory/supplier_specdirectory_init.ldif') }
          it { is_expected.not_to contain_exec('Initialize supplier specdirectory: specdirectory') }
          it { is_expected.not_to contain_file('/etc/dirsrv/slapd-specdirectory/hub_specdirectory_init.ldif') }
          it { is_expected.not_to contain_exec('Initialize hub specdirectory: specdirectory') }
          it { is_expected.not_to contain_file('/etc/dirsrv/slapd-specdirectory/consumer_specdirectory_init.ldif') }
          it { is_expected.not_to contain_exec('Initialize consumer specdirectory: specdirectory') }

          it { is_expected.not_to contain_file('/etc/dirsrv/slapd-specdirectory/supplier_supplier1_init.ldif') }
          it { is_expected.not_to contain_exec('Initialize supplier supplier1: specdirectory') }
          it { is_expected.not_to contain_file('/etc/dirsrv/slapd-specdirectory/hub_hub1_init.ldif') }
          it { is_expected.not_to contain_exec('Initialize hub hub1: specdirectory') }

          it {
            is_expected.to contain_file('/etc/dirsrv/slapd-specdirectory/consumer_consumer1_init.ldif').with(
              ensure: 'file',
              mode: '0440',
              owner: 'custom_user',
              group: 'custom_group',
              content: consumer1_init_custom,
            )
          }
          it {
            is_expected.to contain_exec('Initialize consumer consumer1: specdirectory').with(
              command: 'ldapmodify -h ldap.test.org -p 1389 -x -D "cn=Directory Manager" -w supersecure -f /etc/dirsrv/slapd-specdirectory/consumer_consumer1_init.ldif ; touch /etc/dirsrv/slapd-specdirectory/consumer_consumer1_init.done', # rubocop:disable LineLength
              path: '/usr/bin:/bin',
              creates: '/etc/dirsrv/slapd-specdirectory/consumer_consumer1_init.done',
            ).that_requires(
              [
                'File[/etc/dirsrv/slapd-specdirectory/consumer_consumer1_init.ldif]',
                'Exec[Set up replication: specdirectory]',
              ],
            )
          }
        end
      end
    end
  end
end
