class CreateSvcardProdRelations < ActiveRecord::Migration
  #储值卡产品关系表
  def change
    create_table :svcard_prod_relations do |t|
      t.integer :product_id
      t.integer :product_num
      t.integer :sv_card_id
      t.float :base_price
      t.float :more_price
      t.integer :product_discount
      t.string :category_id
      t.string :pcard_ids
      
      t.timestamps
    end

    add_index :svcard_prod_relations, :product_id
    add_index :svcard_prod_relations, :sv_card_id
  end
end
