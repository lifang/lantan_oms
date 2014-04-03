class CreateChartImages < ActiveRecord::Migration
  def change
    create_table :chart_images do |t|
      t.integer :id
      t.integer :store_id
      t.string :image_url
      t.integer :types
      t.datetime :created_at
      t.datetime :current_day
      t.integer :staff_id
    end
    add_index :chart_images, :store_id
    add_index :chart_images, :created_at
    add_index :chart_images, :types
    add_index :chart_images, :current_day
  end
  
end
