#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../edgeops/files/task_helper.rb'
require 'puppet_x/puppetlabs/netconf/session'
require 'json'

result = PuppetX::Puppetlabs::Netconf::Session.with_session do |session|
  servers = session.task_params['servers']
  enabled = session.task_params.fetch('enabled', true)
  prefer = session.task_params['prefer']

  unless servers && servers.is_a?(Array) && !servers.empty?
    raise "Missing or invalid required parameter 'servers'"
  end

  session.logger.info("Configuring NTP: enabled=#{enabled}, servers=#{servers.join(', ')}")

  # Build OpenConfig NTP configuration XML (strictly matching OpenConfig YANG)
  servers_xml = servers.map do |srv|
    <<~XML
      <server>
            <address>#{srv}</address>
          <config>
            <address>#{srv}</address>
            #{prefer == srv ? '<prefer>true</prefer>' : ''}
          </config>
      </server>
    XML
  end.join

  config = <<~XML
    <system xmlns="http://openconfig.net/yang/system">
      <ntp>
        <config>
          <enabled>#{enabled}</enabled>
        </config>
        <servers>
          #{servers_xml}
        </servers>
      </ntp>
    </system>
  XML

  session.edit_config(config)
  session.logger.info("NTP configuration applied to candidate datastore")
  session.commit
  session.logger.info("NTP configuration committed successfully")

  session.report_result({
    'status' => 'success',
    'enabled' => enabled,
    'servers' => servers,
    'prefer' => prefer,
    'message' => "NTP configuration applied successfully"
  })
end

puts result.to_json
