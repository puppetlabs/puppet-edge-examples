#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../edgeops/files/task_helper.rb'
require 'puppet_x/puppetlabs/netconf/session'
require 'json'

result = PuppetX::Puppetlabs::Netconf::Session.with_session do |session|
  username = session.task_params['username']

  unless username
    raise "Missing required parameter: username"
  end

  session.logger.info("Removing user #{username}")

  # Build OpenConfig user XML for deletion using correct AAA model structure
  config = <<~XML
    <system xmlns="http://openconfig.net/yang/system">
      <aaa>
        <authentication>
          <users>
            <user operation="delete">
              <username>#{username}</username>
            </user>
          </users>
        </authentication>
      </aaa>
    </system>
  XML

  session.edit_config(config)
  session.logger.info("User deletion applied to candidate datastore")
  session.commit
  session.logger.info("User deletion committed successfully")

  session.report_result({
    'status' => 'success',
    'username' => username,
    'message' => "User #{username} removed successfully"
  })
end

puts result.to_json