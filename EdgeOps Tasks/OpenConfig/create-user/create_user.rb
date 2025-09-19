#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../edgeops/files/task_helper.rb'
require 'puppet_x/puppetlabs/netconf/session'
require 'json'

result = PuppetX::Puppetlabs::Netconf::Session.with_session do |session|
  username = session.task_params['username']
  password = session.task_params['password']
  ssh_key = session.task_params['ssh_key']
  role = session.task_params['role']

  unless username && role
    raise "Missing required parameters: username, role"
  end

  unless password || ssh_key
    raise "At least one authentication method required: password or ssh_key (or both)"
  end

  auth_methods = []
  auth_methods << "password" if password
  auth_methods << "SSH key" if ssh_key
  
  session.logger.info("Creating user #{username} with #{auth_methods.join(' and ')}")

  # Build OpenConfig user XML using correct AAA model structure
  # Only include fields that are provided
  config_fields = ["<username>#{username}</username>"]
  config_fields << "<password>#{password}</password>" if password
  config_fields << "<ssh-key>#{ssh_key}</ssh-key>" if ssh_key
  config_fields << "<role>#{role}</role>"
  
  config = <<~XML
    <system xmlns=\"http://openconfig.net/yang/system\">
      <aaa>
        <authentication>
          <users>
            <user>
              <username>#{username}</username>
              <config>
                #{config_fields.join("\n                ")}
              </config>
            </user>
          </users>
        </authentication>
      </aaa>
    </system>
  XML

  session.edit_config(config)
  session.logger.info("User configuration applied to candidate datastore")
  session.commit
  session.logger.info("User configuration committed successfully")

  session.report_result({
    'status' => 'success',
    'username' => username,
    'role' => role,
    'message' => "User #{username} created and SSH key added"
  })
end

puts result.to_json
