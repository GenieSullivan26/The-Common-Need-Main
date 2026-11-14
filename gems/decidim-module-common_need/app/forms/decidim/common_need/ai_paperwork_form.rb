# frozen_string_literal: true

module Decidim
  module CommonNeed
    # Form object for the Encrypted Local AI Paperwork Co-Pilot on Node #OAK-01.
    # Validates the 5 guided paperwork templates and delivery mode ("pdf" or "courier").
    class AiPaperworkForm < Decidim::Form
      mimic :ai_paperwork

      GUIDED_TEMPLATES = [
        "Social Services: CalFresh / SNAP, Medi-Cal & LIHEAP Packet",
        "Legal Aid: Eviction Defense & Record Expungement Intake",
        "Housing: Emergency Rent Relief & Habitability Packet",
        "Public Sector: Municipal ID & Paratransit Fee Waiver",
        "Veteran Services: VA Disability Claim & DD-214 Support Packet",
        "Social Services CalFresh/Medi-Cal/LIHEAP",
        "Legal Aid Eviction Defense",
        "Housing Rent Relief",
        "Public Sector Municipal ID/Paratransit",
        "Veteran Services VA Claim/DD-214"
      ].freeze

      DELIVERY_MODES = %w(pdf courier).freeze

      attribute :template_name, String, default: "Social Services: CalFresh / SNAP, Medi-Cal & LIHEAP Packet"
      attribute :household_size, String, default: "Household Size: 3"
      attribute :language_preference, String, default: "Language: English"
      attribute :situation_notes, String, default: "Standard expedited filing"
      attribute :delivery_mode, String, default: "pdf"
      attribute :care_basket_id, Integer

      validates :template_name, presence: true, inclusion: { in: GUIDED_TEMPLATES }
      validates :household_size, presence: true
      validates :language_preference, presence: true
      validates :situation_notes, presence: true
      validates :delivery_mode, presence: true, inclusion: { in: DELIVERY_MODES }
    end
  end
end
