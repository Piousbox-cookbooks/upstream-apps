#
# Cookbook Name:: tgtapps
# Recipe:: default
#
# Copyright 2011, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

environment = node.chef_environment

packages = %w{ emacs23-nox 
  build-essential 
  openssl 
  libreadline6 
  libreadline6-dev 
  curl 
  git-core 
  zlib1g 
  zlib1g-dev 
  libssl-dev 
  libyaml-dev 
  libsqlite3-0 
  libsqlite3-dev 
  sqlite3 
  libxml2-dev 
  libxslt-dev 
  autoconf 
  libc6-dev 
  ncurses-dev 
  automake 
  libtool 
  bison 
  subversion 
  unzip 
  imagemagick 
  libmagick9-dev
  }

packages.each do |pkg|
  package pkg do
    action :install
  end
end

 gems = %w{ bundler }

gems.each do |gem|
  gem_package gem do
    action :install
  end
end

# iterate over apps databag adn set up each app
data_bag("apps").each do |entry|
  app = data_bag_item("apps", entry)
  log app.to_json

  app_root = "/var/www/#{app['id']}/current"
  doc_root = "/var/www/#{app['id']}/current/public"

  template "/etc/nginx/sites-available/#{app['id']}" do
    source "default-site.erb"
    owner "root"
    group "root"
    mode 0644
    Chef::Log.info("Node environment: #{environment}")
    variables(
              :app => app['id'],
              :server_name => app['domains'][environment],
              :port => app['port'],
              :document_root => doc_root
              )
    only_if {File.exists?(app_root)}
  end

  execute "nxensite #{ app['id'] }" do
    command "/usr/sbin/nxensite #{ app['id']}"
    only_if {File.exists?(app_root)}
  end

  service "nginx" do
    supports :status => true, :restart => true, :reload => true
    action [ :enable, :restart ]
    only_if {File.exists?(app_root)}
  end

  # auto create unicorn.rb per app
  # might be better to not have this in the run
  template "#{app_root}/config/unicorn.rb" do
    owner 'deploy'
    group 'sysadmin'
    source "unicorn.conf.rb.erb"
    mode "0664"
    variables(
              :app => app['id'],
              :port => app['port']
              )
    only_if {File.exists?(app_root)}
  end
end

