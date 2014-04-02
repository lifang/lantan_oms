class CreateChartImages < ActiveRecord::Migration
  def change
    create_table :chart_images,:options => 'AUTO_INCREMENT = 1001' do |t|
      t.integer :id
      t.integer :store_id
      t.string :image_url
      t.integer :types
      t.datetime :current_day
      t.integer :staff_id
      t.timestamps
    end
    add_index :chart_images, :store_id
    add_index :chart_images, :types
    add_index :chart_images, :current_day
  end
  
end
