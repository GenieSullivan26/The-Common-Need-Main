# frozen_string_literal: true

require "decidim/components/namer"

Decidim.register_component(:common_need) do |component|
  component.engine = Decidim::CommonNeed::Engine
  component.admin_engine = Decidim::CommonNeed::AdminEngine
  component.icon = "media/images/decidim_common_need.svg"
  component.permissions_class_name = "Decidim::CommonNeed::Permissions"
  component.serializes_specific_data = false

  component.on(:before_destroy) do |instance|
    raise StandardError, "Cannot destroy this component while active deliveries or hubs exist" if Decidim::CommonNeed::Hub.where(component: instance).any?
  end

  component.register_resource(:hub) do |resource|
    resource.model_class_name = "Decidim::CommonNeed::Hub"
    resource.card = "decidim/common_need/hub_card"
    resource.searchable = true
  end

  component.register_resource(:service_item) do |resource|
    resource.model_class_name = "Decidim::Services::ServiceItem"
    resource.card = "decidim/common_need/item_card"
    resource.searchable = true
  end

  component.register_resource(:delivery) do |resource|
    resource.model_class_name = "Decidim::CommonNeed::Delivery"
    resource.card = "decidim/common_need/delivery_update_banner"
    resource.searchable = false
  end

  component.settings(:global) do |settings|
    settings.attribute :local_node_code, type: :string, default: "#OAK-01"
    settings.attribute :zero_means_testing_enforced, type: :boolean, default: true
    settings.attribute :max_delivery_radius_meters, type: :integer, default: 12_000
    settings.attribute :local_ollama_enabled, type: :boolean, default: true
    settings.attribute :federation_zero_pii_enforced, type: :boolean, default: true
  end

  component.settings(:step) do |settings|
    settings.attribute :allow_basket_checkout, type: :boolean, default: true
    settings.attribute :allow_surplus_posting, type: :boolean, default: true
    settings.attribute :allow_network_voting, type: :boolean, default: true
  end

  component.seeds do |participatory_space|
    require "decidim/common_need/seeds"
    Decidim::CommonNeed::Seeds.new(participatory_space: participatory_space).call
  end
end
