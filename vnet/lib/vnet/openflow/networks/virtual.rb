# -*- coding: utf-8 -*-

module Vnet::Openflow::Networks

  class Virtual < Base

    def network_type
      :virtual
    end

    def flow_options
      @flow_options ||= {:cookie => @cookie}
    end

    def install
      network_md = md_create(:network => @id)
      fo_network_md = flow_options.merge(network_md)

      flows = []
      flows << Flow.create(TABLE_TUNNEL_NETWORK_IDS, 30, {
                             :tunnel_id => @id | TUNNEL_FLAG_MASK
                           }, nil,
                           fo_network_md.merge(:goto_table => TABLE_NETWORK_SRC_CLASSIFIER))
      flows << Flow.create(TABLE_NETWORK_SRC_CLASSIFIER, 40,
                           network_md,
                           nil,
                           flow_options.merge(:goto_table => TABLE_VIRTUAL_SRC))
      flows << Flow.create(TABLE_NETWORK_DST_CLASSIFIER, 40,
                           network_md,
                           nil,
                           flow_options.merge(:goto_table => TABLE_VIRTUAL_DST))

      if @broadcast_mac_address
        flows << Flow.create(TABLE_NETWORK_SRC_CLASSIFIER, 90, {
                               :eth_dst => @broadcast_mac_address
                             }, {}, flow_options)
        flows << Flow.create(TABLE_NETWORK_SRC_CLASSIFIER, 90, {
                               :eth_src => @broadcast_mac_address
                             }, {}, flow_options)
        flows << Flow.create(TABLE_NETWORK_DST_CLASSIFIER, 90, {
                               :eth_dst => @broadcast_mac_address
                             }, {}, flow_options)
        flows << Flow.create(TABLE_NETWORK_DST_CLASSIFIER, 90, {
                               :eth_src => @broadcast_mac_address
                             }, {}, flow_options)
      end

      @dp_info.add_flows(flows)

      ovs_flows = []
      ovs_flows << create_ovs_flow_learn_arp(83, "tun_id=0,")
      ovs_flows << create_ovs_flow_learn_arp(81, "", "load:NXM_NX_TUN_ID\\[\\]\\-\\>NXM_NX_TUN_ID\\[\\],")
      ovs_flows.each { |flow| @dp_info.add_ovs_flow(flow) }
    end

    def update_flows
      flood_actions = @interfaces.select { |interface_id, interface|
        interface[:port_number]
      }.collect { |interface_id, interface|
        { :output => interface[:port_number] }
      }

      flows = []
      flows << Flow.create(TABLE_FLOOD_LOCAL, 1,
                           md_create(:network => @id),
                           flood_actions, flow_options.merge(:goto_table => TABLE_FLOOD_SEGMENT))

      @dp_info.add_flows(flows)
    end

    def create_ovs_flow_learn_arp(priority, match_options = "", learn_options = "")
      #
      # Work around the current limitations of trema / openflow 1.3 using ovs-ofctl directly.
      #
      match_md = md_create(network: @id, remote: nil)
      learn_md = md_create(network: @id, local: nil, vif: nil)

      flow_learn_arp = "table=#{TABLE_VIRTUAL_SRC},priority=#{priority},cookie=0x%x,arp,metadata=0x%x/0x%x,#{match_options}actions=" %
        [@cookie, match_md[:metadata], match_md[:metadata_mask]]
      flow_learn_arp << "learn\\(table=%d,cookie=0x%x,idle_timeout=36000,priority=35,metadata:0x%x,NXM_OF_ETH_DST\\[\\]=NXM_OF_ETH_SRC\\[\\]," %
        [TABLE_VIRTUAL_DST, cookie, learn_md[:metadata]]

      flow_learn_arp << learn_options

      flow_learn_arp << "output:NXM_OF_IN_PORT\\[\\]\\),goto_table:%d" % TABLE_ROUTE_INGRESS
      flow_learn_arp
    end
  end
end
