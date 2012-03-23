# Upstream apps

* Creates capistrano directory structure for an app
* Creates an nginx vhost configured as an upstream server
* If a rack app is detected, creates a unicorn config and upstart script to
  run the app.

## Usage

Create an apps data bag

Create a data bag item for each app:

    {
      "id": "app1",
      "unicorn_port": "8001",

      "server_roles" : [ "appserver" ],

      "production": {
        "domains": [
          "example.com",
          "origin.example.com"
        ]
      },

      "staging": {
        "domains": [
          "origin-staging.example.com",
          "staging.example.com"
        ]
      },

      "dev": {
        "domains": [
          "origin-dev.example.com",
          "dev.example.com"
        ]
      }
    }

### Domains

**production**, **staging**, and **dev** correspond to chef environents. So if the
recipe is running on a node who's environment is **staging**, the recipe will
insert those domains into the nginx vhost.

### Server Roles

Also, the app will only be installed on nodes that have a role listed in the
**server\_roles** array. If **server\_roles** is missing, the app will be installed
by default.