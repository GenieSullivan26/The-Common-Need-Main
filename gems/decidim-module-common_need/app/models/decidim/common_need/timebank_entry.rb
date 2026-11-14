# frozen_string_literal: true

module Decidim
  module CommonNeed
    # Tracks Volunteer Courier distribution shift sign-ups and non-monetary solidarity timebank hours.
    class TimebankEntry < Decidim::CommonNeed::ApplicationRecord
      include Decidim::HasComponent
      include Decidim::Traceable
      include Decidim::Loggable
      include AASM

      self.table_name = "decidim_common_need_timebank_entries"

      component_manifest_name "common_need"

      belongs_to :user,
                 class_name: "Decidim::User",
                 foreign_key: :decidim_user_id,
                 optional: true

      belongs_to :meeting,
                 class_name: "Decidim::Meetings::Meeting",
                 foreign_key: :decidim_meeting_id,
                 optional: true

      validates :shift_title, presence: true
      validates :hours_contributed, numericality: { greater_than: 0 }

      aasm column: :state do
        state :open, initial: true
        state :claimed
        state :completed

        event :claim do
          transitions from: [:open, :claimed], to: :claimed
        end

        event :complete do
          transitions from: [:open, :claimed, :completed], to: :completed
        end
      end
    end
  end
end
