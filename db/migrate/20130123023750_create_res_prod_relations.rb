class CreateResProdRelations < ActiveRecord::Migration
  #预约产品表
  def change
    create_table :res_prod_relations do |t|
      t.integer :product_id
      t.integer :reservation_id
      t.timestamps
    end

    add_index :res_prod_relations, :product_id
    add_index :res_prod_relations, :reservation_id
  end
end
