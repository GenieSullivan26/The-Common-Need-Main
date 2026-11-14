# frozen_string_literal: true

Decidim.register_component(:courier) do |component|
  component.engine = Decidim::Courier::Engine
  component.admin_engine = Decidim::Courier::AdminEngine
  component.icon = "media/images/decidim_courier.svg"
  component.permissions_class_name = "Decidim::CommonNeed::Permissions"
  component.serializes_specific_data = false

  component.register_resource(:delivery_batch) do |resource|
    resource.model_class_name = "Decidim::CommonNeed::Delivery"
    resource.card = "decidim/common_need/route_stop_card"
    resource.searchable = false
  end

  component.settings(:global) do |settings|
    settings.attribute :osrm_endpoint, type: :string, default: "http://osrm:5000"
    settings.attribute :offline_tile_caching_enabled, type: :boolean, default: true
    settings.attribute :zero_means_testing_enforced, type: :boolean, default: true
  end

  component.settings(:step) do |settings|
    settings.attribute :allow_shift_claiming, type: :boolean, default: true
    settings.attribute :allow_stop_confirmation, type: :boolean, default: true
  end
end if defined?(Decidim) && Decidim.respond_to?(:register_component)
