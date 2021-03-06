# -*- coding: utf-8 -*-

module Vnctl::Cli
  class MacLease < Base
    namespace :mac_lease
    api_suffix "/api/mac_leases"

    add_modify_shared_options {
      option :mac_address, :type => :string, :desc => "The mac address to lease"
    }
    add_required_options [:mac_address]

    define_standard_crud_commands
  end
end
