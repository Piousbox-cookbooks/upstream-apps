


node[:mongodb][:replset][:name] = node.chef_environment
Chef::Log.info "Chef Environment: #{node.chef_environment}"

node[:mongodb][:replset][:initial_nodes] = 3
