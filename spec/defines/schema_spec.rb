require 'spec_helper'

describe 'ds_389::schema' do
  let(:pre_condition) do
    'include ::ds_389
    ::ds_389::service { "specdirectory": }'
  end
  let(:title) { 'specschema' }

  on_supported_os(facterversion: '2.4').each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      context 'with required params' do
        let(:params) do
          {
            server_id: 'specdirectory',
            source: 'puppet:///specfiles/specschema.ldif',
          }
        end

        it { is_expected.to compile }

        it {
          is_expected.to contain_file('/etc/dirsrv/slapd-specdirectory/schema/specschema.ldif').with(
            ensure: 'file',
            mode: '0440',
            owner: 'dirsrv',
            group: 'dirsrv',
            source: 'puppet:///specfiles/specschema.ldif',
          ).that_notifies('Service[dirsrv@specdirectory]')
        }
      end

      context 'with all params' do
        let(:params) do
          {
            server_id: 'specdirectory',
            source: 'puppet:///specfiles/specschema.ldif',
            user: 'custom_user',
            group: 'custom_group',
          }
        end

        it { is_expected.to compile }

        it {
          is_expected.to contain_file('/etc/dirsrv/slapd-specdirectory/schema/specschema.ldif').with(
            ensure: 'file',
            mode: '0440',
            owner: 'custom_user',
            group: 'custom_group',
            source: 'puppet:///specfiles/specschema.ldif',
          ).that_notifies('Service[dirsrv@specdirectory]')
        }
      end
    end
  end
end
