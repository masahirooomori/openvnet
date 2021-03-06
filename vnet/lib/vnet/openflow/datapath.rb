# -*- coding: utf-8 -*-

module Vnet::Openflow

  # Read-only thread-safe object to allow other actors to access
  # static information about this datapath.
  class DatapathInfo

    attr_reader :id
    attr_reader :uuid
    attr_reader :display_name

    attr_reader :datapath_map

    attr_reader :dc_segment_id
    attr_reader :ipv4_address

    def initialize(datapath_map)
      @datapath_map = datapath_map

      @id = datapath_map.id
      @uuid = datapath_map.uuid
      @display_name = datapath_map.display_name

      @dc_segment_id = datapath_map.dc_segment_id
      @ipv4_address = IPAddr.new(@datapath_map.ipv4_address, Socket::AF_INET)
    end

  end

  # OpenFlow datapath allows us to send OF messages and ovs-ofctl
  # commands to a specific bridge/switch.
  class Datapath
    include Celluloid
    include Celluloid::Logger
    include FlowHelpers

    attr_reader :dp_info

    attr_reader :controller
    attr_reader :dpid
    attr_reader :dpid_s
    attr_reader :ovs_ofctl

    # Do not update any values of the datapath db for outside of the
    # Datapath actor.
    attr_reader :datapath_map
    attr_reader :datapath_info

    attr_reader :switch

    attr_reader :dc_segment_manager
    attr_reader :interface_manager
    attr_reader :network_manager
    attr_reader :port_manager
    attr_reader :route_manager
    attr_reader :service_manager
    attr_reader :tunnel_manager
    attr_reader :translation_manager

    def initialize(ofc, dp_id, ofctl = nil)
      @dpid = dp_id
      @dpid_s = "0x%016x" % @dpid

      @dp_info = DpInfo.new(controller: ofc,
                            datapath: self,
                            dpid: dp_id,
                            ovs_ofctl: ofctl)

      @controller = @dp_info.controller
      @ovs_ofctl = @dp_info.ovs_ofctl

      # TODO: Remove these...
      @dc_segment_manager = @dp_info.dc_segment_manager
      @interface_manager = @dp_info.interface_manager
      @network_manager = @dp_info.network_manager
      @port_manager = @dp_info.port_manager
      @route_manager = @dp_info.route_manager
      @service_manager = @dp_info.service_manager
      @tunnel_manager = @dp_info.tunnel_manager
      @translation_manager = @dp_info.translation_manager
    end

    def datapath_batch
      @datapath_map.batch
    end

    def datapath_id
      @datapath_map && @datapath_map.id
    end

    def inspect
      "<##{self.class.name} dpid:#{@dp_info && @dp_info.dpid}>"
    end

    def ipv4_address
      ipv4_value = @datapath_map.ipv4_address
      ipv4_value && IPAddr.new(ipv4_value, Socket::AF_INET)
    end

    def create_switch
      @switch = Switch.new(self)
      @switch.create_default_flows

      # TODO: Don't store the datapath_map...
      @datapath_map = MW::Datapath[:dpid => @dp_info.dpid_s]

      if @datapath_map.nil?
        warn log_format('could not find dpid in database')
        return
      end

      initialize_datapath_info

      @switch.switch_ready
    end

    #
    # Flow modification methods:
    #

    # Use dp_info.
    def add_flow(flow)
      @controller.pass_task {
        @controller.send_flow_mod_add(@dp_info.dpid, flow.to_trema_hash)
      }
    end

    def add_ovs_flow(flow_str)
      @ovs_ofctl.add_ovs_flow(flow_str)
    end

    def add_ovs_10_flow(flow_str)
      @ovs_ofctl.add_ovs_10_flow(flow_str)
    end

    # Use dp_info.
    def del_cookie(cookie, cookie_mask = 0xffffffffffffffff)
      options = {
        :command => Controller::OFPFC_DELETE,
        :table_id => Controller::OFPTT_ALL,
        :out_port => Controller::OFPP_ANY,
        :out_group => Controller::OFPG_ANY,
        :cookie => cookie,
        :cookie_mask => cookie_mask
      }

      @controller.pass_task {
        @controller.public_send_flow_mod(@dp_info.dpid, options)
      }
    end

    # Use dp_info.
    def add_flows(flows)
      return if flows.blank?
      @controller.pass_task {
        flows.each { |flow|
          @controller.send_flow_mod_add(@dp_info.dpid, flow.to_trema_hash)
        }
      }
    end

    # Use dp_info.
    def send_message(message)
      @controller.pass_task {
        @controller.public_send_message(@dp_info.dpid, message)
      }
    end

    # Use dp_info.
    def send_packet_out(message, port_no)
      @controller.pass_task {
        @controller.public_send_packet_out(@dp_info.dpid, message, port_no)
      }
    end

    #
    # Port modification methods:
    #

    # Obsolete, use DpInfo directly.
    def add_tunnel(tunnel_name, remote_ip)
      @ovs_ofctl.add_tunnel(tunnel_name, remote_ip)
    end

    def delete_tunnel(tunnel_name)
      debug log_format('delete tunnel', "#{tunnel_name}")
      @ovs_ofctl.delete_tunnel(tunnel_name)
    end

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      "#{@dp_info.dpid_s} datapath: #{message}" + (values ? " (#{values})" : '')
    end

    def initialize_datapath_info
      @datapath_info = DatapathInfo.new(@datapath_map)

      @dp_info.datapath_manager.set_datapath_info(@datapath_info)
      @dp_info.dc_segment_manager.set_datapath_info(@datapath_info)
      @dp_info.interface_manager.set_datapath_info(@datapath_info)
      @dp_info.network_manager.set_datapath_info(@datapath_info)
      @dp_info.route_manager.set_datapath_info(@datapath_info)
      @dp_info.service_manager.set_datapath_info(@datapath_info)
      @dp_info.tunnel_manager.set_datapath_info(@datapath_info)
      @dp_info.translation_manager.set_datapath_info(@datapath_info)
    end

  end

end
