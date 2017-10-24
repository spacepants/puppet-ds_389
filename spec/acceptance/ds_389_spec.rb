require 'spec_helper_acceptance'

describe 'ds_389 class' do
  context 'default parameters' do
    # Using puppet_apply as a helper
    it 'is expected to work idempotently with no errors' do
      pp = <<-EOS
      class { 'ds_389':
        instances => {
          'foo' => {
            'root_dn'           => 'cn=Directory Manager',
            'root_dn_pass'      => 'supersecret',
            'suffix'            => 'dc=example,dc=com',
            'cert_db_pass'      => 'secret',
            'server_id'         => 'foo',
          },
        },
      }
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end

    describe port(389) do
      it { is_expected.to be_listening }
    end

    describe port(636) do
      it { is_expected.to be_listening }
    end

    describe service('dirsrv@foo') do
      it { is_expected.to be_enabled }
      it { is_expected.to be_running }
    end
  end

  if ENV['EXTERNAL_CERT']
    context 'when using external ssl' do
      it 'is expected to work idempotently with no errors' do
        # cleanup previous spec instance
        cleanup = <<-EOS
        service { 'dirsrv@foo':
          ensure => 'stopped',
          enable => 'false',
        } ->
        file { '/etc/init.d/dirsrv@foo':
          ensure  => 'absent',
        } ->
        file { '/etc/dirsrv/slapd-foo':
          ensure  => 'absent',
          recurse => true,
          force   => true,
        }
        EOS
        apply_manifest(cleanup, catch_failures: true)

        scp_to(master, ENV['EXTERNAL_CERT'], '/tmp/external.pem')
        scp_to(master, ENV['EXTERNAL_KEY'], '/tmp/external-key.pem')
        scp_to(master, ENV['EXTERNAL_CA'], '/tmp/external-ca.pem')
        pp = <<-EOS
        class { 'ds_389':
          instances => {
            'bar' => {
              'root_dn'      => 'cn=Directory Manager',
              'root_dn_pass' => 'supersecret',
              'suffix'       => 'dc=example,dc=com',
              'cert_db_pass' => 'secret',
              'server_id'    => 'bar',
              'ssl'          => {
                'cert_path'      => '/tmp/external.pem',
                'key_path'       => '/tmp/external-key.pem',
                'ca_bundle_path' => '/tmp/external-ca.pem',
                'ca_cert_names'  => [
                  'InCommon RSA Server CA - The USERTRUST Network',
                  'USERTrust RSA Certification Authority - AddTrust AB',
                  'AddTrust External CA Root - AddTrust AB',
                ],
                'cert_name'      => $::fqdn,
              },
            },
          },
        }
        EOS

        # Run it twice and test for idempotency
        apply_manifest(pp, catch_failures: true)
        apply_manifest(pp, catch_changes: true)
      end

      describe port(389) do
        it { is_expected.to be_listening }
      end

      describe port(636) do
        it { is_expected.to be_listening }
      end

      describe service('dirsrv@bar') do
        it { is_expected.to be_enabled }
        it { is_expected.to be_running }
      end
    end
  end
end
