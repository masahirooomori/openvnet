# -*- coding: utf-8 -*-

Sequel.migration do
  up do
    create_table(:datapaths) do
      primary_key :id
      String :uuid, :unique => true, :null=>false
      String :display_name, :null=>false
      FalseClass :is_connected, :null=>false, :default => false
      String :dpid, :null=>false
      Integer :dc_segment_id, :index => true
      Bignum :ipv4_address, :null=>false
      String :node_id, :null=>false
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
    end

    create_table(:datapath_networks) do
      primary_key :id
      Integer :datapath_id, :index => true, :null=>false
      Integer :network_id, :index => true, :null=>false
      Integer :mac_address_id, :index => true
      FalseClass :is_connected, :null=>false
    end

    create_table(:datapath_route_links) do
      primary_key :id
      Integer :datapath_id, :index => true, :null=>false
      Integer :route_link_id, :index => true, :null=>false
      Integer :mac_address_id, :index => true
      FalseClass :is_connected, :null=>false
    end

    create_table(:dc_segments) do
      primary_key :id
      String :uuid, :unique => true, :null=>false
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
    end

    create_table(:dhcp_ranges) do
      primary_key :id
      String :uuid, :unique => true, :null=>false
      Bignum :range_begin, :null=>false
      Bignum :range_end, :null=>false
      Integer :network_id, :index => true, :null => false
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
    end

    create_table(:interfaces) do
      primary_key :id
      String :uuid, :unique => true, :null=>false
      String :mode, :default => 'vif',:null => false
      String :display_name

      String :port_name, :index => true, :null => true

      # Should be a relation allowing for multiple active/owner
      # datapath ids.
      Integer :active_datapath_id, :index => true
      Integer :owner_datapath_id, :index => true

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
    end

    create_table(:interface_security_groups) do
      primary_key :id
      Integer :interface_id, :index => true, :null => false
      Integer :security_group_id, :index => true, :null => false
      DateTime :deleted_at
    end

    create_table(:ip_addresses) do
      primary_key :id
      Integer :network_id, :index => true, :null => false
      Bignum :ipv4_address, :null=>false
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      unique [:network_id, :ipv4_address]
    end

    create_table(:ip_leases) do
      primary_key :id
      String :uuid, :unique => true, :null=>false
      Integer :interface_id, :index => true, :null => false
      Integer :mac_lease_id, :index => true, :null => false
      Integer :ip_address_id, :index => true, :null=>false
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at
      FalseClass :is_deleted, :null=>false
    end

    create_table(:mac_addresses) do
      primary_key :id
      String :uuid, :unique => true, :null=>false
      Bignum :mac_address, :unique => true, :null=>false
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
    end

    create_table(:mac_leases) do
      primary_key :id
      String :uuid, :unique => true, :null=>false
      Integer :interface_id, :index => true
      Integer :mac_address_id, :index => true, :null => false
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at
    end

    create_table(:networks) do
      primary_key :id
      String :uuid, :unique => true, :null=>false
      String :display_name, :null=>false
      Bignum :ipv4_network, :null=>false
      Integer :ipv4_prefix, :default=>24, :null=>false
      String :domain_name
      String :network_mode
      FalseClass :editable
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false

      index [:ipv4_network, :ipv4_prefix]
    end

    create_table(:network_services) do
      primary_key :id
      String :uuid, :unique => true, :null=>false
      Integer :interface_id, :index => true
      String :display_name, :index => true, :null=>false
      Integer :incoming_port
      Integer :outgoing_port
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
    end

    create_table(:routes) do
      primary_key :id
      String :uuid, :unique => true, :null => false
      Integer :interface_id, :index => true
      Integer :route_link_id, :index => true, :null => false

      String :route_type, :default => 'gateway', :null => false

      # Change network id to segment id once supported.
      Integer :network_id, :null => false
      Bignum  :ipv4_network, :null => false
      Integer :ipv4_prefix, :default => 24, :null => false

      Boolean :ingress, :default => true, :null => false
      Boolean :egress,  :default => true, :null => false

      DateTime :created_at, :null => false
      DateTime :updated_at, :null => false
    end

    create_table(:route_links) do
      primary_key :id
      String :uuid, :unique => true, :null=>false
      Integer :mac_address_id, :index => true

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
    end

    create_table(:security_groups) do
      primary_key :id
      String :uuid, :unique => true, :null => false
      String :display_name, :null => false
      String :rules, :null => false, :default => ""
      String :description
      DateTime :deleted_at
    end

    create_table(:tunnels) do
      primary_key :id
      String :uuid, :unique => true, :null=>false
      String :display_name, :index => true, :null => false
      Integer :src_datapath_id, :index => true, :null => false
      Integer :dst_datapath_id, :index => true, :null => false

      index [:src_datapath_id, :dst_datapath_id]
    end

    create_table(:vlan_translations) do
      primary_key :id
      Integer :interface_id, :index => true
      Bignum :mac_address
      Integer :vlan_id
      Integer :network_id
    end
  end

  down do
    drop_table(:datapaths,
               :datapath_networks,
               :datapath_route_links,
               :dc_segments,
               :dhcp_ranges,
               :interfaces,
               :interface_security_groups,
               :ip_addresses,
               :ip_leases,
               :mac_addresses,
               :mac_leases,
               :networks,
               :network_services,
               :routes,
               :route_links,
               :security_groups,
               :tunnels,
               :vlan_translations
               )
  end
end
