# Arista cEOS System Management Module for Puppet EdgeOps

This module provides example NETCONF tasks for managing system settings on Arista cEOS devices. It is designed for use with the Puppet EdgeOps Module, enabling automated system configuration through standardized workflows.

🤖 **AI-Assisted:** These examples were generated using Puppet Edge and the Puppet Edge MCP server.

## Purpose

The System Management module examples help network administrators automate the configuration of system-level settings on supported network devices. By leveraging NETCONF, these tasks ensure consistent and reliable system management.

## Tasks Overview

The `tasks` subfolder contains individual NETCONF task examples, each demonstrating a specific system management action. Currently, the available example covers:

- Updating the system admin password on a device
- Managing NTP servers

Each task is self-contained and can be used as a reference or integrated into your own automation workflows.

## Usage

1. Review the tasks in the `tasks` subfolder to find the action you need.
2. Customize the task parameters as required for your environment.
3. Execute the tasks using Puppet EdgeOps to manage system settings on your network devices.

## Requirements

- Puppet EdgeOps Module
- Network devices supporting NETCONF and OpenConfig models

## Support

For more information, refer to the Puppet EdgeOps documentation or contact your network automation team. 