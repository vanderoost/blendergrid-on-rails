class AddMissingForeignKeys < ActiveRecord::Migration[8.2]
  def change
    add_foreign_key :projects, :uploads
    add_foreign_key :projects, :orders

    add_foreign_key :uploads, :users

    add_foreign_key :project_blend_checks, :projects
    add_foreign_key :project_benchmarks, :projects
    add_foreign_key :project_renders, :projects
    add_foreign_key :blender_scenes, :projects

    add_foreign_key :orders, :users
    add_foreign_key :order_items, :orders
    add_foreign_key :order_items, :projects

    add_foreign_key :credit_entries, :users
    add_foreign_key :credit_entries, :orders
    add_foreign_key :credit_entries, :refunds
    add_foreign_key :refunds, :order_items

    add_foreign_key :articles, :users
    add_foreign_key :page_variants, :landing_pages

    add_foreign_key :requests, :users
    add_foreign_key :events, :requests

    add_foreign_key :upload_zip_checks, :uploads
  end
end
