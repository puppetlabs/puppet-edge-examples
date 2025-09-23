#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../edgeops/files/task_helper.rb'

require 'puppet_x/puppetlabs/netconf/session'
require 'json'

result = PuppetX::Puppetlabs::Netconf::Session.with_session do |session|
  params = session.task_params

  password = params['password']
  password_hashed = params['password_hashed']
  target = params.fetch('target', 'candidate')
  commit_flag = params.fetch('commit', true)

  # Validate parameters: either password or password_hashed must be provided
  unless (password && !password.empty?) || (password_hashed && !password_hashed.empty?)
    raise "Missing required parameter: either 'password' or 'password_hashed' must be supplied"
  end

  session.logger.info('Updating admin password')

  # Escape function for XML
  def xml_escape(str)
    str.to_s.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;')
  end

  password_escaped = xml_escape(password)
  password_hashed_escaped = xml_escape(password_hashed)

  # Build config using openconfig-aaa namespace
  config = <<~XML
    <config>
      <aaa xmlns="http://openconfig.net/yang/aaa">
        <authentication>
          <admin-user>
            <config>
              #{password ? "<admin-password>#{password_escaped}</admin-password>" : ''}
              #{password_hashed ? "<admin-password-hashed>#{password_hashed_escaped}</admin-password-hashed>" : ''}
            </config>
          </admin-user>
        </authentication>
      </aaa>
    </config>
  XML

  session.logger.debug("Built admin-password config: #{config}")

  # Apply the configuration
  session.edit_config(config)
  session.logger.info("Edit-config applied to #{target} datastore")

  # Commit if using candidate and requested
  if target == 'candidate' && commit_flag
    session.commit
    session.logger.info('Committed candidate datastore')
  end

  session.report_result({
    'status' => 'success',
    'target' => target,
    'committed' => (target == 'candidate' ? commit_flag : false),
    'message' => 'Admin password updated'
  })
end

puts result.to_json
