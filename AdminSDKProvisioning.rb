# encoding: utf-8
# Encoding.default_external = Encoding::UTF_8 
# rdoc doc markup : http://docs.seattlerb.org/rdoc/RDoc/Markup.html#label-Other+directives

# Google API Ruby client library reference : https://developers.google.com/api-client-library/ruby/
#
# Google API Ruby client library doc : http://www.rubydoc.info/github/google/google-api-ruby-client/Google/APIClient
#
# Admin Directory API Ruby client library : https://developers.google.com/api-client-library/ruby/apis/admin/directory_v1
# Admin Directory API Ruby client librairy reference : http://www.rubydoc.info/github/google/google-api-ruby-client/Google/Apis/AdminDirectoryV1
#
# Migrating from Provisioning to Directory API : https://developers.google.com/admin-sdk/directory/v1/guides/migrate
#
# Scopes : https://developers.google.com/admin-sdk/directory/v1/guides/authorizing
#
# Help : http://thomasleecopeland.com/2015/04/27/google-directory-api-ruby-client.html


module AdminSDKProvisioning # :nodoc
	require 'google/api_client'

	class GApps
		@@token_credentialuri = 'https://accounts.google.com/o/oauth2/token'
		@@audience = 'https://accounts.google.com/o/oauth2/token'
		@@scope = [
		 'https://www.googleapis.com/auth/admin.directory.user',
		 'https://www.googleapis.com/auth/admin.directory.user.alias',
		 'https://www.googleapis.com/auth/admin.directory.group',  
		 'https://www.googleapis.com/auth/admin.directory.group.member'
		]
		@@default_application_name = "my_application"
		@@default_application_version = "v0.0.0"

		##
		# Creates a connection to your Google Apps domain
		#
		# required params  :
		# * +:pkcs12_file+ 			=> <i>(string)</i> path to your pkcs12_file provided by Google,
		# * +:domain+ 				=> <i>(string)</i> your domain name,
		# * +:service_account_email+ 	=> <i>(string)</i> the service account email provided by Google,
		# * +:admin_email+ 			=> <i>(string)</i> email of one of your domain administrators,
		#   
		# optional params :
		# * +:application_name+ 		=> <i>(string)</i> your client application name,
		# * +:version+ 				=> <i>(string)</i> your client application version
		#
		# example :
		#  include AdminSDKProvisioning
		#  sae = "123456789123456789@developer.gserviceaccount.com"
		#  admin_email = "admin@mydomain.com"
		#  pkcs12_file = "/path/to/privatekey.p12"
		#  myapps = GApps.new(service_account_email: sae, admin_email: admin_email, pkcs12_file: pkcs12_file, domain: "mydomain.com")
		def initialize(**params)
			p12file = params[:pkcs12_file]
			domain = params[:domain]
			service_account_email = params[:service_account_email]
			act_on_behalf_email = params[:admin_email]
			application_name = params[:application_name] || @@default_application_name
			version = params[:version] || @@default_application_version

			key = Google::APIClient::KeyUtils.load_from_pkcs12(p12file, 'notasecret')
			@client = Google::APIClient.new(:application_name => application_name, :version => version)

			@client.authorization = Signet::OAuth2::Client.new(
  				:token_credential_uri => @@token_credentialuri,
  				:audience => @@audience,
  				:scope => @@scope,
  				:issuer => service_account_email,
  				:person => act_on_behalf_email,
  				:sub => act_on_behalf_email,
  				:signing_key => key)

			@client.authorization.fetch_access_token!

			@api = @client.discovered_api("admin", "directory_v1")
		end

		def unJSON(json_serialized) # :nodoc
			return JSON.parse(json_serialized,{:symbolize_names => :true})
		end


		# Users
		# =======================================================================


		# Returns an object
		# The username can be the user's primary email address, alias email address or Google unique user ID
		#   ex :
		#             myapps = Gapps.new()
		#             user = myapps.retrieve_user('john.doe@mydomain.com')
		def retrieve_user(username)
			res = @client.execute(
  			:api_method => @api.users.get,
  			:parameters => {'userKey' => username}
  			)
  			return unJSON(res.body)
		end

		# Creates an account in your domain, returns an object
		# required params :
		# * +:primaryEmail+	=> <i>(string)</i> the user's primary email, must be unique
		# *	+:password+ 		=> <i>(string)</i> any combination of ASCII characters (length between 8 and 100). Value as a base 16 bits encoded hash value recommended. Must be a valid hash key if :hash_function is specified.
		# *	+:first_name+ 	=> <i>(string)</i> the user's first name
		# * +:family_name+	=> <i>(string)</i> the user's last name
		#
		#   optional params:
		# 			:addresses_array => an array [] of address objects,
		# 							address_object = {
		#  								'country' 			=> <i>(string)</i> country,
		# 								'countryCode' 		=> <i>(string)</i> country code in ISO 3166-1 standard,
		#  								'customType'		=> <i>(string)</i> custom value is the address type is "custom",
		# 								'extendedAddress'	=> <i>(string)</i> extended address, ex : sub-region,
		# 								'locality'			=> <i>(string)</i> town or city of the address,
		#  								'poBox'				=> <i>(string)</i> post office box,
		# 								'postalCode' 		=> <i>(string)</i> zip or postal code,
		# 								'primary' 			=> <i>(boolean)</i> if this object is the user's primary address. The addresses array may contain only one primary address,
		#  								'region' 			=> <i>(string)</i> abbreviated province or state,
		# 								'sourceIsStructured' => <i>(boolean)</i> if the user's address is formatted,
		# 								'streetAddress'		=> <i>(string)</i> the street address,
		# 								'type'				=> <i>(string)</i> address type. Allowed values : "custom", "home", "other", "work" }
		#
		#    		:change_password_next_login => <i>(boolean)</i> if the user is forced to change its password at next login,
		#
		#  			:emails_array => an array [] of email objects,
		# 							email_object = {
		# 								'address'			=> <i>(string)</i> the user's email address. Also serves as the email ID. This value can be the user's primary email address or an alias,
		# 								'customType'		=> <i>(string)</i> custom value if if the email type is "custom",
		# 								'primary'			=> <i>(boolean)</i> if the email object is the user's primary email. Only one primary email is allowed in the eamils array,
		# 								'type' 				=> <i>(string)</i> email account type. Valid values : "custom", "home", "other", "work" }
		#  			
		# 			:externalIds_array => an array [] of externalID objects,
		# 							externalID_object = {
		#  								'customType'		=> <i>(string)</i> custom type value if external ID type is "custom",
		#  								'type' 				=> <i>(string)</i> external ID type. Allowed values : "account", "custom", "customer", "network", "organization",
		# 								'value' 			=> <i>(string)</i> the value of the ID }
		#
		# 			:hash_function => <i>(string)</i> if you store the hash format of the password, set the corresponding hash function value : "SHA-1", "MD5", "CRYPT",
		# 			
		#  			:ims_array => an array [] of im objects,
		# 							im_object = {
		#  								'customProtocol' 	=> <i>(string)</i> custom protocol string if protocol value is "custom_protocol",
		#  								'customType' 		=> <i>(string)</i> custom type string if the im type is "custom",
		# 								'im'				=> <i>(string)</i> the user's IM network ID,
		#  								'primary' 			=> <i>(boolean)</i> if this is the user's primary IM. Only one primary IM is alloaed in the array,
		#  								'protocol'			=> <i>(string)</i> IM network protocol identifier. Values are : "custom_protocol", "aim", "gtalk", "icq", "jabber", "msn", "net_meeting", "qq", "skype", "yahoo",
		# 								'type' 				=> <i>(string)</i> type values are : "custom", "home", "other", "work" }
		#
		#  			:global_address_list_included => <i>(boolean)</i> if the user's profile is visible in the Google Apps global address list when the contact sharing feature is enabled for the domain,
		#
		# 			:ip_whitelisted => <i>(boolean)</i> if true, the user's IP address is white listed,
		#
		# 			:organization_path => <i>(string)</i> full path of the user's parent organization. If it's the top-level, the value is "/",
		#
		# 			:organizations_array => an array [] of organization objects,
		# 							organization_object = {
		#  								'costCenter' 	=> <i>(string)</i> cost center of the user's organization,
		#  								'customType'	=> <i>(string)</i> custom type value if the type is "custom",
		#  								'department'	=> <i>(string)</i> department within the organization,
		# 								'description'	=> <i>(string)</i> description of the organization,
		# 								'domain' 		=> <i>(string)</i> the domain the organization belongs to,
		# 								'location' 		=> <i>(string)</i> physical location of the organization,
		# 								'name' 			=> <i>(string)</i> name of the organization,
		# 								'primary' 		=> <i>(boolean)</i> if it's the user's primary organization. Only one allowed in the array,
		# 								'symbol' 		=> <i>(string)</i> organization symbol string,
		# 								'title'			=> <i>(string)</i> user's title within the organization,
		# 								'type' 			=> <i>(string)</i> organization type, possible values : "unknown", "school", "work", "domain_only",
		#  								'customType'	=> <i>(string)</i> custom type value if type is "custom" }
		# 	
		#  			:phones_array => an array [] of phone objects,
		# 						phone_object = {
		#  								'customtype' => <i>(string)</i> custom type value if phone type is "custom",
		#  								'primary'    => <i>(boolean)</i> if it's the user's primary phone number. Only one allowed in the array,
		# 								'type'       => <i>(string)</i> allowed values : "custom", "home", "work", "other", "home_fax", "work_fax", "mobile", "pager", "compain_main", "assistant", "car", "radio", "isdn", "callback", "telex", "tty_ttd", "work_mobile", "work_pager", "main", "grand_central",
		# 								'value'		 => <i>(string)</i> a human-readable phone number }
		#
		# 			:relations_array => an array [] of relation objects,
		# 						relation_object = {
		# 								'customType' => <i>(string)</i> custom type value is relation type is "custom",
	 	# 								'type' 		 => <i>(string)</i> possible values are : "custom", "spouse", "child", "mother", "father", "parent", "brother", "sister", "friend", "relative", "domestic_partner", "manager", "assistant", "referred_by", "partner",
	 	# 								'value'		 => <i>(string)</i> the name the person the user is related to }
	 	#
	 	# 			:suspended => <i>(boolean)</i> indicates if the user is suspended
	 	# 

	 	# api documentation here  : https://developers.google.com/admin-sdk/directory/v1/reference/users/insert?hl=fr
		def create_user(**args)
			new_user = @api.users.insert.request_schema.new({
					'password' => args[:password],
					'primaryEmail' => args[:email],
					'name' => { 'familyName' => args[:family_name], 'givenName' => args[:first_name], 'fullName' => args[:first_name] + ' ' + args[:family_name] },
					'addresses' => :addresses_array,
					'emails' => :emails_array,
					'changePasswordAtNextLogin' => :change_password_next_login,
					'externalIds' => :externalIds_array,
					#'hashFunction' => :hash_function,
					'ims' => :ims_array,
					'includeInGlobalAddressList' => args[:includeInGlobalAddressList],
					'ipWhitelisted' => :ip_whitelisted,
					#'orgUnitPath' => :organization_path,
					'organizations' => :organizations_array,
					'phones' => :phones_array,
					'relations' => :relations_array,
					'suspended' => :suspended
				})
			res = @client.execute(
  			:api_method => @api.users.insert,
  			:body_object => new_user
  			)
  			return unJSON(res.body) 			
		end

		# https://developers.google.com/admin-sdk/directory/v1/guides/manage-users#update_user
		def update_user(userKey, args)
			res = @client.execute(
				:api_method => @api.users.update,
				:parameters => args
				)
			ret = res.body.empty? ? "" : unJSON(res.body)
			return ret
		end


		def delete_user(userKey)
			res = @client.execute(
				:api_method => @api.users.delete,
				:parameters => {'userKey' => userKey}
				)
			ret = res.body.empty? ? "" : unJSON(res.body)
			return ret   # empty if successful
		end


		def list_aliases(username)
			res = @client.execute(
  			:api_method => @api.users.aliases.list,
  			:parameters => {'userKey' => username}
  			)
  			return unJSON(res.body)
		end


		# Groups
		# ==================================================

		def delete_group(groupKey)
			res = @client.execute(
				:api_method => @api.groups.delete,
				:parameters => {'groupKey' => groupKey}
				)
			ret = res.body.empty? ? "" : unJSON(res.body)
			return ret  # empty if successful
		end


		def create_group(**args)
			new_group = @api.groups.insert.request_schema.new({
				'email' => args[:email],
				'description' => args[:description],
				'name' => args[:name]
				})
			res = @client.execute(
				:api_method => @api.groups.insert,
				:body_object => new_group
				)
			return unJSON(res.body)
		end


		def retrieve_group(groupKey)
			res = @client.execute(
				:api_method => @api.groups.get,
				:parameters => {'groupKey' => groupKey}
				)
			return unJSON(res.body)
		end

		def list_domain_groups()
		end



		# Members
		# ======================================

		def delete_group_member()
		end

		# insert_group_member(group_email: email_of_the_group, email: member_email)
		def insert_group_member(**args)
			new_member = @api.members.insert.request_schema.new({
				'email' => args[:email],
				'role' => 'MEMBER'
				})
			res = @client.execute(
				:api_method => @api.members.insert,
				:parameters => {'groupKey' => args[:group_email]},
				:body_object => new_member
				)
			return unJSON(res.body)
		end

		def list_group_members()
		end



	end
end
