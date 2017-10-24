require 'spec_helper'

describe 'ds_389::add' do
  let(:pre_condition) { 'class {"ds_389": }' }
  let(:title) { 'specadd' }

  on_supported_os(facterversion: '2.4').each do |os, os_facts|
    context "on #{os}" do
      let(:facts) do
        os_facts.merge(
          fqdn: 'foo.example.com',
        )
      end

      context 'with required params' do
        let(:params) do
          {
            server_id: 'specdirectory',
            source: 'puppet:///specfiles/specadd.ldif',
            root_dn: 'cn=Directory Manager',
            root_dn_pass: 'supersecure',
          }
        end

        it { is_expected.to compile }

        it {
          is_expected.to contain_file('/etc/dirsrv/slapd-specdirectory/specadd.ldif').with(
            ensure: 'file',
            mode: '0440',
            owner: 'dirsrv',
            group: 'dirsrv',
            source: 'puppet:///specfiles/specadd.ldif',
          )
        }
        it {
          is_expected.to contain_exec('Modify ldif specadd: specdirectory').with(
            command: 'cat /etc/dirsrv/slapd-specdirectory/specadd.ldif | ldapadd -h foo.example.com -p 636 -x -D "cn=Directory Manager" -w supersecure ; touch /etc/dirsrv/slapd-specdirectory/specadd.done', # rubocop:disable LineLength
            path: '/usr/bin:/bin',
            creates: '/etc/dirsrv/slapd-specdirectory/specadd.done',
          ).that_requires('File[/etc/dirsrv/slapd-specdirectory/specadd.ldif]')
        }
      end

      context 'with all params' do
        let(:params) do
          {
            server_id: 'specdirectory',
            source: 'puppet:///specfiles/specadd.ldif',
            root_dn: 'cn=Directory Manager',
            root_dn_pass: 'supersecure',
            server_host: 'ldap.test.org',
            server_ssl_port: 1636,
            user: 'specuser',
            group: 'specgroup',
          }
        end

        it { is_expected.to compile }

        it {
          is_expected.to contain_file('/etc/dirsrv/slapd-specdirectory/specadd.ldif').with(
            ensure: 'file',
            mode: '0440',
            owner: 'specuser',
            group: 'specgroup',
            source: 'puppet:///specfiles/specadd.ldif',
          )
        }
        it {
          is_expected.to contain_exec('Modify ldif specadd: specdirectory').with(
            command: 'cat /etc/dirsrv/slapd-specdirectory/specadd.ldif | ldapadd -h ldap.test.org -p 1636 -x -D "cn=Directory Manager" -w supersecure ; touch /etc/dirsrv/slapd-specdirectory/specadd.done', # rubocop:disable LineLength
            path: '/usr/bin:/bin',
            creates: '/etc/dirsrv/slapd-specdirectory/specadd.done',
          ).that_requires('File[/etc/dirsrv/slapd-specdirectory/specadd.ldif]')
        }
      end
    end
  end
end
