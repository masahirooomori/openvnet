# -*- coding: utf-8 -*-

module Vnet::NodeApi
  class Datapath < Base
    class << self
      def create(options)
        super.tap do |datapath|
          dispatch_event(ADDED_DATAPATH, id: datapath.id)
        end
      end

      def destroy(uuid)
        super.tap do |datapath|
          dispatch_event(REMOVED_DATAPATH, id: datapath.id, node_id: datapath.node_id)
        end
      end
    end
  end
end