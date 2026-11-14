# frozen_string_literal: true

class CreateDecidimCommonNeedHubs < ActiveRecord::Migration[7.2]
  def change
    create_table :decidim_common_need_hubs do |t|
      t.bigint :decidim_component_id, null: false, index: { name: "index_decidim_common_need_hubs_on_component_id" }
      t.bigint :decidim_author_id, null: false
      t.string :decidim_author_type, null: false
      t.string :slug, null: false
      t.jsonb :title, null: false, default: {}
      t.jsonb :subtitle, null: false, default: {}
      t.string :badge_label
      t.decimal :member_audit_score, precision: 3, scale: 2, null: false, default: 5.0
      t.string :address
      t.st_point :coordinates, geographic: true, srid: 4326
      t.string :ein_number
      t.string :verification_status, null: false, default: "verified"
      t.integer :surplus_nourishment_lbs_monthly, null: false, default: 0
      t.decimal :staff_hours_reclaimed_weekly, precision: 5, scale: 1, null: false, default: 0.0
      t.string :category_keys, array: true, null: false, default: []

      t.timestamps
    end

    add_index :decidim_common_need_hubs, :coordinates, using: :gist, name: "index_decidim_common_need_hubs_on_coordinates"
    add_index :decidim_common_need_hubs, [:decidim_component_id, :slug], unique: true, name: "index_decidim_common_need_hubs_on_component_and_slug"
    add_index :decidim_common_need_hubs, [:decidim_author_id, :decidim_author_type], name: "index_decidim_common_need_hubs_on_author"
  end
end
