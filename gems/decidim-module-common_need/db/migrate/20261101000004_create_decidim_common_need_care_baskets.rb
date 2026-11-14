# frozen_string_literal: true

class CreateDecidimCommonNeedCareBaskets < ActiveRecord::Migration[7.2]
  def change
    create_table :decidim_common_need_care_baskets do |t|
      t.bigint :decidim_component_id, null: false, index: { name: "index_decidim_common_need_care_baskets_on_component_id" }
      t.bigint :decidim_user_id, index: { name: "index_decidim_common_need_care_baskets_on_user_id" }
      t.boolean :bring_up_porch_steps, null: false, default: true
      t.boolean :wait_60s_at_door, null: false, default: true
      t.integer :total_meals, null: false, default: 0
      t.integer :total_protective_items, null: false, default: 0
      t.decimal :total_weight_lbs, precision: 6, scale: 2, null: false, default: 0.0
      t.string :routing_node_code, null: false, default: "#OAK-01"
      t.string :access_principle, null: false, default: "UNCONDITIONAL SOLIDARITY"
      t.string :state, null: false, default: "open"

      t.timestamps
    end

    create_table :decidim_common_need_care_basket_items do |t|
      t.bigint :decidim_common_need_care_basket_id, null: false, index: { name: "index_care_basket_items_on_basket_id" }
      t.bigint :decidim_services_service_item_id, index: { name: "index_care_basket_items_on_service_item_id" }
      t.string :item_name, null: false
      t.string :hub_label
      t.string :badge_summary, null: false, default: "Solidarity Share"
      t.integer :quantity, null: false, default: 1
      t.integer :meals_count, null: false, default: 0
      t.decimal :weight_lbs, precision: 6, scale: 2, null: false, default: 0.0
      t.integer :protective_gear_count, null: false, default: 0

      t.timestamps
    end
  end
end
