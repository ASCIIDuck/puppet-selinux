require 'spec_helper'

# $stdout.puts self.catalogue.to_yaml

describe 'selinux::module', :type => :define do
  let(:title) { 'selinux::module' }

  describe "loading module" do
    modname = 'rsynclocal'
    source = "puppet:///modules/selinux/#{modname}.te"
    let(:title) { modname }
    let(:params) {{
      :source      => source,
      :modules_dir => '/var/lib/puppet/selinux',
    }}
    let(:facts) { {
        :osfamily      => 'RedHat',
    } }

    it { should create_class('selinux') }
    it { should create_class('selinux::params') }
    it { should create_class('selinux::config') }
    it { should create_class('selinux::install') }
    it { should create_package('selinux-policy-devel') }
    it { should create_package('checkpolicy') }
    it { should create_selinux__module(modname) }
    it { should create_file("/var/lib/puppet/selinux/#{modname}.te")\
      .with(
        'ensure' => 'present',
        'source' => source,
        'tag'    => 'selinux-module'
      ) } 
    it { should create_file("/var/lib/puppet/selinux/#{modname}.mod")\
      .with(
        'tag'    => ['selinux-module-build','selinux-module'],
      ) }
    it { should create_file("/var/lib/puppet/selinux/#{modname}.pp")\
      .with(
        'tag'    => ['selinux-module-build','selinux-module'],
      ) }
    it { should create_exec("#{modname}-buildmod")\
      .with(
        'command' => "checkmodule -M -m -o #{modname}.mod #{modname}.te",
      ) }
    it { should create_exec("#{modname}-buildpp")\
      .with(
        'command' => "semodule_package -m #{modname}.mod -o #{modname}.pp",
      ) }
    it { should create_exec("#{modname}-install")\
      .with(
        'command' => "semodule -i #{modname}.pp",
      ) }
  end
end
