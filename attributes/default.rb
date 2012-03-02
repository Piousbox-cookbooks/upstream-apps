
default[:nginx][:http_port] = 8080
default[:unicorn][:worker_processes] = 16
default[:upstream_apps][:health_check] = true