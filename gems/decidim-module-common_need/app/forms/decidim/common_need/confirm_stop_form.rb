# frozen_string_literal: true

module Decidim
  module CommonNeed
    # Form object for Volunteer Courier confirmation of a route pickup or dropoff stop.
    class ConfirmStopForm < Decidim::Form
      mimic :confirm_stop

      attribute :route_stop_id, Integer
      attribute :delivery_id, Integer
      attribute :stop_number, Integer, default: 2
      attribute :confirmed_at, Time, default: -> { Time.current }
      attribute :consolidation_notes, String, default: "N95 masks consolidated • Window narrowed to 2:38–2:45 PM"

      validates :route_stop_id, presence: true
      validates :delivery_id, presence: true
      validates :confirmed_at, presence: true
    end
  end
end
