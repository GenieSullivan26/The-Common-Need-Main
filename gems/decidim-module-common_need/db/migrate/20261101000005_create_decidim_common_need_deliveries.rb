# frozen_string_literal: true

class CreateDecidimCommonNeedDeliveries < ActiveRecord::Migration[7.2]
  def change
    create_table :decidim_common_need_deliveries do |t|
      t.bigint :decidim_component_id, null: false, index: { name: "index_decidim_common_need_deliveries_on_component_id" }
      t.bigint :decidim_common_need_care_basket_id, index: { name: "index_decidim_common_need_deliveries_on_basket_id" }
      t.bigint :decidim_user_id, index: { name: "index_decidim_common_need_deliveries_on_user_id" }
      t.bigint :volunteer_user_id, index: { name: "index_decidim_common_need_deliveries_on_volunteer_id" }
      t.string :batch_code, null: false, default: "BATCH #OAK-409"
      t.string :shift_code, null: false, default: "SHIFT #OAK-409"
      t.string :route_title, null: false, default: "Deep East Oakland → Fruitvale Loop"
      t.datetime :window_start_at
      t.datetime :window_end_at
      t.string :window_headline, null: false, default: "Window: 2:35 PM – 2:50 PM (2 Stops Away)"
      t.boolean :bring_up_porch_steps, null: false, default: true
      t.boolean :wait_60s_at_door, null: false, default: true
      t.string :handoff_instructions, null: false, default: "Handoff: Walk up 4 porch steps & wait 60s"
      t.string :dropoff_block_label, null: false, default: "1400 Block of 62nd Ave"
      t.st_point :dropoff_coordinates, geographic: true, srid: 4326
      t.integer :total_duration_minutes, null: false, default: 42
      t.decimal :total_distance_miles, precision: 5, scale: 2, null: false, default: 4.6
      t.text :osrm_polyline
      t.jsonb :osrm_maneuvers, null: false, default: []
      t.integer :milestone_step, null: false, default: 2
      t.boolean :crates_staged_at_ramp, null: false, default: false
      t.string :state, null: false, default: "hubs_loaded"

      t.timestamps
    end

    add_index :decidim_common_need_deliveries, :dropoff_coordinates, using: :gist, name: "index_decidim_common_need_deliveries_on_dropoff_coords"
    add_index :decidim_common_need_deliveries, :batch_code, name: "index_decidim_common_need_deliveries_on_batch_code"
  end
end
