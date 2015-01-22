# encoding: utf-8
# vim: ft=ruby expandtab shiftwidth=2 tabstop=2

require 'serverspec'
require 'pathname'
require 'net/ssh'
require 'spec_helper'
require 'yaml'

include SpecInfra::Helper::Ssh
include SpecInfra::Helper::DetectOS

_conf = YAML.load(
  File.open(
    'provision/default.yml',
    File::RDONLY
  ).read
)

if File.exists?('site.yml')
  _site = YAML.load(
    File.open(
      'site.yml',
      File::RDONLY
    ).read
  )
  _conf.merge!(_site) if _site.is_a?(Hash)
end

describe package('httpd') do
  it { should be_installed }
end

describe service('httpd') do
  it { should be_enabled }
  it { should be_running }
end

describe port(80) do
    it { should be_listening }
end

describe port(443) do
    it { should be_listening }
end

describe 'PHP config parameters' do
  context  php_config('default_charset') do
    its(:value) { should eq 'UTF-8' }
  end

  context  php_config('mbstring.language') do
    its(:value) { should eq 'neutral' }
  end

  context  php_config('mbstring.internal_encoding') do
    its(:value) { should eq 'UTF-8' }
  end

  context php_config('date.timezone') do
    its(:value) { should eq 'UTC' }
  end

  context php_config('short_open_tag') do
    its(:value) { should eq 'Off' }
  end

  context php_config('session.save_path') do
    its(:value) { should eq '/tmp' }
  end

end

describe command('wp --version') do
  let(:disable_sudo) { true }
  it { should return_exit_status 0 }
end

describe command('wp help dictator') do
  let(:disable_sudo) { true }
  it { should return_exit_status 0 }
end

describe command("wget -q http://" + File.join(_conf['ip'], _conf['wp_home'], '/') + " -O - | head -100 | grep generator") do
    it { should return_stdout /<meta name="generator" content="WordPress .*"/i }
end

describe command("wget -q http://" + File.join(_conf['ip'], _conf['wp_siteurl'], '/readme.html')) do
    it { should return_exit_status 0 }
end

describe command("wget --no-check-certificate -q https://" + File.join(_conf['ip'], _conf['wp_home'], '/') + " -O - | head -100 | grep generator") do
  it { should return_stdout /<meta name="generator" content="WordPress .*"/i }
end

_conf['plugins'].each do |plugin|
  describe file(File.join(_conf['document_root'], _conf['wp_siteurl'], 'wp-content/plugins', plugin, 'readme.txt')) do
    let(:disable_sudo) { true }
    it { should be_file }
  end
end

describe file(File.join(_conf['document_root'], _conf['wp_home'], '.htaccess')) do
  let(:disable_sudo) { true }
  it { should be_file }
end

describe file(File.join(_conf['document_root'], _conf['wp_home'], 'index.php')) do
  let(:disable_sudo) { true }
  it { should be_file }
end

describe file(File.join(_conf['document_root'], _conf['wp_siteurl'], 'wp-load.php')) do
  let(:disable_sudo) { true }
  it { should be_file }
end