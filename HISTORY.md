## 0.4.0 (2010-03-23)

* Only deploy app if node has a role included in the list of server roles in
  the app data bag: app["server_roles"].any? { |role| node.role?(role) }

## 0.3.1 (2012-03-08)

* Only generate unicorn config/upstart script if config.ru is detected
* Actually start the upstart script!
* Skipped 0.3.0 as this was a version already running on audi-apps but
  never commited

## 0.2.9 (2012-03-08)

* Revert disabling of default-ssl, upstream apps shouldn't care about default-ssl

## 0.2.8 (2012-03-01)

* Make health check proxy optional

## 0.2.7 (2012-02-24)

* Add an upstart script for each app
  If app is named "facebooktabs", service is named "facebooktabs-app"

## 0.2.6 (2012-02-23)

* Add a health check proxy vhost as the default vhost

## 0.2.2 (2012-01-26)

* Add support for custom vhosts for upstream apps

## 0.2.1 (2012-01-26)

* Add support for multiple host names and host header variables for vhost
  template
