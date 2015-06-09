# AdminSDKProvisioning
Ruby high-level client library for Google Apps Provisioning

*Requires google/api Ruby gem*

This library provides high-level commands to manage Google Apps users, groups, and members.

Exemple :    
```ruby
require ('./AdminSDKProvisioning.rb')

include AdminSDKProvisioning
admin_email = "admin@mydomain.com"
sae = "123456789987456321@developer.gserviceaccount.com"
pkcs12_file = "keyfile.p12"
myapps = GApps.new(service_account_email: sae, admin_email: admin_email, pkcs12_file: pkcs12_file, domain: "mydomain.com")

# users
user = myapps.retrieve_user('foo@mydomain.com')
pp user

new_user = myapps.create_user( first_name: "zorro", family_name: "delavega", email: "zorro@mydomain.com", password: "tornado")

# groups
new_group = myapps.create_group(email: "sgt.garcia@mydomain.com", name: "Garcia", description: "Sergent Garcia Fan Club")
group = myapps.retrieve_group("sgt.garcia@mydomain.com")
```

