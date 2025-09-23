#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../edgeops/files/task_helper.rb'

require 'puppet_x/puppetlabs/netconf/session'
require 'json'

# Use the Session wrapper provided by the edgeops library
result = PuppetX::Puppetlabs::Netconf::Session.with_session do |session|
  params = session.task_params

  username = params['username']
  public_key = params['public_key']
  key_name = params.fetch('key_name', nil)
  description = params.fetch('description', nil)
  target = params.fetch('target', 'candidate')
  commit_flag = params.fetch('commit', true)

  # Validate required parameters
  unless username && !username.empty?
    raise "Missing required parameter 'username'"
  end

  unless public_key && !public_key.empty?
    raise "Missing required parameter 'public_key'"
  end

  session.logger.info("Enabling SSH key for user #{username}")

  # Build an OpenConfig keychain-style config. Many vendors augment OpenConfig keychain
  # to support user SSH keys. We'll place the key under openconfig-keychain's 'keys' entry
  # using a conservative XML structure. If the device requires vendor-specific augmentations,
  # this can be adjusted.

  key_id = key_name || "#{username}-pubkey-#{Time.now.to_i}"

  # Escape XML special chars in public_key and description
  def xml_escape(str)
    str.to_s.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;')
  end

  public_key_escaped = xml_escape(public_key)
  description_escaped = xml_escape(description)

  config = <<~XML
    <config>
      <keychains xmlns="http://openconfig.net/yang/oc-keychain">
        <keychain>
          <name>#{username}-keychain</name>
          <config>
            <name>#{username}-keychain</name>
          </config>
          <keys>
            <key>
              <key-id>#{key_id}</key-id>
              <config>
                <key-id>#{key_id}</key-id>
                <key-type>RSA</key-type>
                <key-data>#{public_key_escaped}</key-data>
                #{description_escaped && !description_escaped.empty? ? "<description>#{description_escaped}</description>" : ""}
              </config>
            </key>
          </keys>
        </keychain>
      </keychains>
      <system xmlns="http://openconfig.net/yang/system">
        <users>
          <user>
            <name>#{username}</name>
            <config>
              <name>#{username}</name>
            </config>
            <authorized-keys>
              <key>
                <key-id>#{key_id}</key-id>
                <config>
                  <key-id>#{key_id}</key-id>
                  <key-data>#{public_key_escaped}</key-data>
                </config>
              </key>
            </authorized-keys>
          </user>
        </users>
      </system>
    </config>
  XML

  session.logger.debug("Built config: #{config}")

  # Apply the configuration
  session.edit_config(config)
  session.logger.info("Edit-config applied to #{target} datastore")

  # Commit if requested and using candidate datastore
  if target == 'candidate' && commit_flag
    session.commit
    session.logger.info('Committed candidate datastore')
  end

  session.report_result({
    'status' => 'success',
    'username' => username,
    'key_id' => key_id,
    'target' => target,
    'committed' => (target == 'candidate' ? commit_flag : false),
    'message' => "SSH key added for user #{username} (key_id=#{key_id})"
  })
end

puts result.to_json
