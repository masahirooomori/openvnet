# -*- coding: utf-8 -*-

module Vnet::Openflow::Connections
  class Base
    include Vnet::Openflow::FlowHelpers
    include Celluloid::Logger

    CM = Vnet::Openflow::ConnectionManager

    EGRESS_IDLE_TIMEOUT  = 550
    INGRESS_IDLE_TIMEOUT = 600

    def self.cookie(interface_id)
      COOKIE_TYPE_CONTRACK | CM::COOKIE_TAG_INGRESS_CONNECTION | interface_id
    end

    def cookie(interface_id)
      self.class.cookie(interface_id)
    end

    def open(message)
      interface_id = message.cookie & COOKIE_ID_MASK

      [
        flow_create(:default,
                    table: TABLE_INTERFACE_EGRESS_FILTER,
                    priority: 21,
                    match: {
                      eth_src:   message.packet_info.eth_src,
                      eth_type: message.eth_type,
                      ipv4_src: message.ipv4_src,
                      ipv4_dst: message.ipv4_dst,
                    }.merge(match_egress(message)),
                    idle_timeout: EGRESS_IDLE_TIMEOUT,
                    cookie: cookie(interface_id),
                    goto_table: TABLE_NETWORK_SRC_CLASSIFIER),
        flow_create(:default,
                    table: TABLE_INTERFACE_INGRESS_FILTER_LOOKUP,
                    priority: 10,
                    match: {
                      eth_dst:   message.packet_info.eth_src,
                      eth_type: ETH_TYPE_IPV4,
                      ipv4_src:   message.ipv4_dst,
                      ipv4_dst:   message.ipv4_src,
                    }.merge(match_ingress(message)),
                    match_metadata: { interface: interface_id },
                    idle_timeout: INGRESS_IDLE_TIMEOUT,
                    cookie: cookie(interface_id),
                    goto_table: TABLE_OUTPUT_INTERFACE_INGRESS)
      ]
    end

    def match_egress(message)
      raise NotImplementedError, "match_egress"
    end

    def match_ingress(message)
      raise NotImplementedError, "match_ingress"
    end
  end
end
