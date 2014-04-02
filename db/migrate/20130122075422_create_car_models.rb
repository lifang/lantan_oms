class CreateCarModels < ActiveRecord::Migration
  def change
    create_table :car_models do |t|
      t.string :name
      t.integer :car_brand_id
      t.timestamps
    end

    add_index :car_models, :name
    add_index :car_models, :car_brand_id
  end
end
