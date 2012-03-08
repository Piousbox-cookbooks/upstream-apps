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

%w{default}.each do |site|
  execute "disable-sites-enabled-#{site}" do
    command "/usr/sbin/nxdissite #{site}"
    only_if { File.exists? "/etc/nginx/sites-enabled/#{site}" }
  end
end

if node[:upstream_apps][:health_check]
  # add the health check proxy vhost as the default vhost
  template "/etc/nginx/sites-available/_health-check" do
    source "health-check.erb"
    owner "root"
    group "root"
    mode 0644
  end

  execute "nxensite _health-check" do
    command "/usr/sbin/nxensite _health-check"
  end
end

# iterate over apps databag adn set up each app
data_bag("apps").each do |entry|
  app = data_bag_item("apps", entry)
  log app.to_json

  app_root    = "/var/www/#{app['id']}/current"
  doc_root    = "/var/www/#{app['id']}/current/public"
  shared_root = "/var/www/#{app['id']}/shared"
  env_config  = app[environment]

  directory shared_root do
    owner 'deploy'
    group 'sysadmin'
    recursive true
  end

  # Don't write a default vhost if this app has a custom one
  unless env_config['vhost']
    template "/etc/nginx/sites-available/#{app['id']}" do
      source "upstream-app.erb"
      owner "root"
      group "root"
      mode 0644
      Chef::Log.info("Node environment: #{environment}")
      variables(
        :app           => app['id'],
        :server_names  => env_config['domains'],
        :host_header   => env_config['domains'].first,
        :document_root => doc_root
      )
      # only_if {File.exists?(app_root)}
    end
  end

  execute "nxensite #{ app['id'] }" do
    command "/usr/sbin/nxensite #{ app['id']}"
    only_if {File.exists?(app_root)}
  end

  service "nginx" do
    supports :status => true, :restart => true, :reload => true
    action [ :enable, :restart ]
  end

  if File.exist?("#{app_root}/config.ru")
    Chef::Log.info("Rack app detected for #{app['id']}, generating unicorn hooks")

    # auto create unicorn.rb per app
    # might be better to not have this in the run
    template "#{shared_root}/unicorn.rb" do
      owner 'deploy'
      group 'sysadmin'
      source "unicorn.conf.rb.erb"
      mode "0664"
      variables(
        :app => app['id'],
        :port => app['unicorn_port']
      )
      # only_if {File.exists?(app_root)}
    end

    # Creat an upstart script for this app
    upstart_script_name = "#{app['id']}-app"

    template "/etc/init/#{upstart_script_name}.conf" do
      source "unicorn-upstart.conf.erb"
      owner "root"
      group "root"
      mode "0664"

      variables(
        :app_name       => app['id'],
        :app_root       => app_root,
        :log_file       => "#{app_root}/log/unicorn.log",
        :unicorn_config => "#{shared_root}/unicorn.rb",
        :unicorn_binary => "bundle exec unicorn",
        :rack_env       => environment
      )
    end

    link "/etc/init.d/#{upstart_script_name}" do
      to "/lib/init/upstart-job"
    end

    service upstart_script_name do
      provider Chef::Provider::Service::Upstart
      supports :status => true, :restart => true
      action [ :enable, :start ]
    end

  end

end

