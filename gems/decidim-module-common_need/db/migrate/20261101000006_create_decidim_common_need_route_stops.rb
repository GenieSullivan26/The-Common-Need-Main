# frozen_string_literal: true

class CreateDecidimCommonNeedRouteStops < ActiveRecord::Migration[7.2]
  def change
    create_table :decidim_common_need_route_stops do |t|
      t.bigint :decidim_common_need_delivery_id, null: false, index: { name: "index_decidim_common_need_route_stops_on_delivery_id" }
      t.bigint :decidim_common_need_hub_id, index: { name: "index_decidim_common_need_route_stops_on_hub_id" }
      t.integer :stop_number, null: false
      t.string :stop_type, null: false, default: "pickup"
      t.string :title, null: false
      t.string :address_label
      t.string :manifest_summary
      t.string :handoff_note
      t.string :scheduled_window
      t.datetime :confirmed_at
      t.st_point :coordinates, geographic: true, srid: 4326
      t.string :state, null: false, default: "pending"

      t.timestamps
    end

    add_index :decidim_common_need_route_stops, :coordinates, using: :gist, name: "index_decidim_common_need_route_stops_on_coordinates"
    add_index :decidim_common_need_route_stops, [:decidim_common_need_delivery_id, :stop_number], unique: true, name: "index_route_stops_on_delivery_and_stop_number"
  end
end
