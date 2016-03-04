#
# Author:: Baptiste Courtois (<b.courtois@criteo.com>)
# Cookbook Name:: sql_server
# Recipe:: configure
#
# Copyright:: 2011-2016, Chef Software, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

instance_name = node['sql_server']['instance_name']

# Compute service name based on sql server instance name
service_name = (instance_name != 'MSSQLSERVER') ? "MSSQL$#{instance_name}" : instance_name

# Compute registry version based on sql server version
reg_version = node['sql_server']['reg_version'] ||
              case node['sql_server']['version']
              when '2008' then 'MSSQL10.'
              when '2008R2' then 'MSSQL10_50.'
              when '2012' then 'MSSQL11.'
              when '2014' then 'MSSQL12.'
              when '2016' then 'MSSQL13.'
              else raise "Unsupported sql_server version '#{node['sql_server']['version']}'"
              end

reg_prefix = "HKLM\\SOFTWARE\\Microsoft\\Microsoft SQL Server\\#{reg_version}#{instance_name}\\MSSQLServer"

# Configure Tcp settings - static tcp ports
registry_key "#{reg_prefix}\\SuperSocketNetLib\\Tcp\\IPAll" do
  values [{ name: 'Enabled', type: :dword, data: node['sql_server']['tcp_enabled'] ? 1 : 0 },
          { name: 'TcpPort', type: :string, data: node['sql_server']['port'].to_s },
          { name: 'TcpDynamicPorts', type: :string, data: node['sql_server']['tcp_dynamic_ports'].to_s }]
  recursive true
  notifies :restart, "service[#{service_name}]", :immediately
end

# Configure Named Pipes settings
registry_key "#{reg_prefix}\\SuperSocketNetLib\\Np" do
  values [{ name: 'Enabled', type: :dword, data: node['sql_server']['np_enabled'] ? 1 : 0 }]
  recursive true
  notifies :restart, "service[#{service_name}]", :immediately
end

# Configure Shared Memory settings
registry_key "#{reg_prefix}\\SuperSocketNetLib\\Sm" do
  values [{ name: 'Enabled', type: :dword, data: node['sql_server']['sm_enabled'] ? 1 : 0 }]
  recursive true
  notifies :restart, "service[#{service_name}]", :immediately
end

# Configure Via settings
registry_key "#{reg_prefix}\\SuperSocketNetLib\\Via" do
  values [{ name: 'DefaultServerPort', type: :string, data: node['sql_server']['via_default_port'].to_s },
          { name: 'Enabled', type: :dword, data: node['sql_server']['via_enabled'] ? 1 : 0 },
          { name: 'ListenInfo', type: :string, data: node['sql_server']['via_listen_info'].to_s }]
  recursive true
  notifies :restart, "service[#{service_name}]", :immediately
end

service service_name do
  action [:start, :enable]
  restart_command %(powershell.exe -C "restart-service '#{service_name}' -force")
end
