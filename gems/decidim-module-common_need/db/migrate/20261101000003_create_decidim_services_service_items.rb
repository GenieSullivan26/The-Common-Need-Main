# frozen_string_literal: true

class CreateDecidimServicesServiceItems < ActiveRecord::Migration[7.2]
  def change
    create_table :decidim_services_service_items do |t|
      t.bigint :decidim_component_id, null: false, index: { name: "index_decidim_services_service_items_on_component_id" }
      t.bigint :decidim_common_need_hub_id, null: false, index: { name: "index_decidim_services_service_items_on_hub_id" }
      t.bigint :decidim_author_id, null: false
      t.string :decidim_author_type, null: false
      t.string :category_key, null: false, index: { name: "index_decidim_services_service_items_on_category_key" }
      t.string :title, null: false
      t.string :dietary_and_safety_tags
      t.string :yield_summary
      t.integer :stock_quantity, null: false, default: 20
      t.integer :meals_count, null: false, default: 0
      t.decimal :weight_lbs, precision: 6, scale: 2, null: false, default: 0.0
      t.integer :protective_gear_count, null: false, default: 0
      t.string :interaction_mode, null: false, default: "add_share"
      t.string :cta_label, null: false, default: "+ Add Share"
      t.string :paperwork_template_name
      t.st_point :pickup_coordinates, geographic: true, srid: 4326
      t.string :state, null: false, default: "available"

      t.timestamps
    end

    add_index :decidim_services_service_items, :pickup_coordinates, using: :gist, name: "index_decidim_services_service_items_on_pickup_coords"
    add_index :decidim_services_service_items, [:decidim_author_id, :decidim_author_type], name: "index_decidim_services_service_items_on_author"
  end
end
