# frozen_string_literal: true

class CreateDecidimCommonNeedTimebankEntries < ActiveRecord::Migration[7.2]
  def change
    create_table :decidim_common_need_timebank_entries do |t|
      t.bigint :decidim_component_id, null: false, index: { name: "index_decidim_common_need_timebank_entries_on_component_id" }
      t.bigint :decidim_user_id, index: { name: "index_decidim_common_need_timebank_entries_on_user_id" }
      t.bigint :decidim_meeting_id, index: { name: "index_decidim_common_need_timebank_entries_on_meeting_id" }
      t.string :shift_title, null: false
      t.string :pickup_address
      t.integer :households_count, null: false, default: 4
      t.decimal :distance_miles, precision: 5, scale: 2, null: false, default: 4.6
      t.string :transport_mode, null: false, default: "walking_bicycle_vehicle"
      t.decimal :hours_contributed, precision: 5, scale: 2, null: false, default: 2.0
      t.string :node_code, null: false, default: "#OAK-01"
      t.string :state, null: false, default: "open"

      t.timestamps
    end
  end
end
