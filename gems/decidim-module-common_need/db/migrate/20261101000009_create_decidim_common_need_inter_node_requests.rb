# frozen_string_literal: true

class CreateDecidimCommonNeedInterNodeRequests < ActiveRecord::Migration[7.2]
  def change
    create_table :decidim_common_need_inter_node_requests do |t|
      t.bigint :decidim_component_id, null: false, index: { name: "index_decidim_common_need_inter_node_requests_on_component_id" }
      t.string :request_code, null: false
      t.string :requesting_node_code, null: false
      t.string :requesting_node_name, null: false
      t.string :source_node_codes, array: true, null: false, default: ["#OAK-01", "#BER-04"]
      t.string :request_type, null: false, default: "surplus"
      t.string :priority, null: false, default: "HIGH PRIORITY"
      t.text :need_summary, null: false
      t.datetime :dispatched_at
      t.string :state, null: false, default: "open"

      t.timestamps
    end

    add_index :decidim_common_need_inter_node_requests, :request_code, unique: true, name: "index_decidim_common_need_inter_node_requests_on_request_code"
  end
end
