class CreateSharedProducts < ActiveRecord::Migration
  def change
    drop_table :shared_materials

    create_table :shared_products do |t|
      t.string :code
      t.string :name
      t.string :standard
      t.string :unit
      t.integer :product_id
      t.timestamps
    end
  end
end
