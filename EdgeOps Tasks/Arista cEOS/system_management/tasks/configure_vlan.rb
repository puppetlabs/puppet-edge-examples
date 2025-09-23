#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../edgeops/files/task_helper.rb'
require 'puppet_x/puppetlabs/netconf/session'
require 'json'

result = PuppetX::Puppetlabs::Netconf::Session.with_session do |session|
  vlan_id = session.task_params['vlan_id']
  name = session.task_params['name']
  description = session.task_params['description']
  routing_ips = session.task_params['routing_ips']

  unless vlan_id && name
    raise "Missing required parameters 'vlan_id' or 'name'"
  end

  session.logger.info("Configuring VLAN #{vlan_id} (#{name})")

  # Build OpenConfig VLAN configuration
  vlan_config = <<~XML
    <config>
      <vlans xmlns="http://openconfig.net/yang/vlan">
        <vlan>
          <vlan-id>#{vlan_id}</vlan-id>
          <config>
            <vlan-id>#{vlan_id}</vlan-id>
            <name>#{name}</name>
            #{description ? "<description>#{description}</description>" : ""}
          </config>
        </vlan>
      </vlans>
    </config>
  XML

  # Build OpenConfig interface configuration for routing IPs
  ip_config = ""
  if routing_ips && routing_ips.any?
    ip_config = <<~XML
      <config>
        <interfaces xmlns="http://openconfig.net/yang/interfaces">
          <interface>
            <name>Vlan#{vlan_id}</name>
            <config>
              <name>Vlan#{vlan_id}</name>
              <type xmlns:ianaift="urn:ietf:params:xml:ns:yang:iana-if-type">ianaift:l3ipvlan</type>
              <enabled>true</enabled>
            </config>
            <subinterfaces>
              <subinterface>
                <index>0</index>
                <config>
                  <index>0</index>
                </config>
                <ipv4>
                  <addresses>
                    #{routing_ips.select { |ip| ip.include?('/') && ip =~ /\d+\.\d+\.\d+\.\d+/ }.map { |ip| "<address><ip>#{ip.split('/')[0]}</ip><config><ip>#{ip.split('/')[0]}</ip><prefix-length>#{ip.split('/')[1]}</prefix-length></config></address>" }.join}\n                  </addresses>
                </ipv4>
                <ipv6>
                  <addresses>
                    #{routing_ips.select { |ip| ip.include?(':') }.map { |ip| "<address><ip>#{ip.split('/')[0]}</ip><config><ip>#{ip.split('/')[0]}</ip><prefix-length>#{ip.split('/')[1]}</prefix-length></config></address>" }.join}\n                  </addresses>
                </ipv6>
              </subinterface>
            </subinterfaces>
          </interface>
        </interfaces>
      </config>
    XML
  end

  # Apply VLAN configuration
  session.edit_config(vlan_config)
  session.logger.info("VLAN configuration applied to candidate datastore")

  # Apply interface configuration if needed
  if ip_config != ""
    session.edit_config(ip_config)
    session.logger.info("Interface configuration for routing IPs applied to candidate datastore")
  end

  session.commit
  session.logger.info("Configuration committed successfully")

  session.report_result({
    'status' => 'success',
    'vlan_id' => vlan_id,
    'name' => name,
    'description' => description,
    'routing_ips' => routing_ips,
    'message' => "VLAN #{vlan_id} (#{name}) configured successfully"
  })
end

puts result.to_json
