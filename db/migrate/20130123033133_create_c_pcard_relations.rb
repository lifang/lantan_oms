class CreateCPcardRelations < ActiveRecord::Migration
  #客户套餐卡表
  def change
    create_table :c_pcard_relations do |t|
      t.integer :customer_id
      t.integer :package_card_id
      t.datetime :ended_at
      t.integer :status
      t.string :content
      t.float :price
      t.integer :order_id
      t.integer :return_types, :default=>0
      t.integer :store_id
      t.timestamps
    end

    add_index :c_pcard_relations, :customer_id
    add_index :c_pcard_relations, :package_card_id
    add_index :c_pcard_relations, :status
    add_index :c_pcard_relations, :order_id
  end
end
