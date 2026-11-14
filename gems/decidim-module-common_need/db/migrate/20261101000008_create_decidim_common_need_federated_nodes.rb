# frozen_string_literal: true

class CreateDecidimCommonNeedFederatedNodes < ActiveRecord::Migration[7.2]
  def change
    create_table :decidim_common_need_federated_nodes do |t|
      t.bigint :decidim_component_id, null: false, index: { name: "index_decidim_common_need_federated_nodes_on_component_id" }
      t.string :node_code, null: false
      t.string :name, null: false
      t.string :domain, null: false
      t.string :deployment_mode, null: false, default: "Standalone Sovereign Docker"
      t.string :osrm_region, null: false, default: "Bay Area / NorCal OSRM"
      t.string :oauth_application_uid
      t.integer :active_hubs_count, null: false, default: 4
      t.integer :households_served_monthly, null: false, default: 312
      t.decimal :shift_fill_rate_pct, precision: 5, scale: 2, null: false, default: 94.2
      t.integer :surplus_rescued_lbs, null: false, default: 1840
      t.integer :latency_ms, null: false, default: 18
      t.integer :household_pii_bytes_on_hub, null: false, default: 0
      t.datetime :last_synced_at
      t.string :state, null: false, default: "healthy"

      t.timestamps
    end

    add_index :decidim_common_need_federated_nodes, :node_code, unique: true, name: "index_decidim_common_need_federated_nodes_on_node_code"
    add_index :decidim_common_need_federated_nodes, :domain, unique: true, name: "index_decidim_common_need_federated_nodes_on_domain"
  end
end
