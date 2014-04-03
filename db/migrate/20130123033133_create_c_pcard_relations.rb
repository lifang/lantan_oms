class CreateCPcardRelations < ActiveRecord::Migration
  #客户套餐卡表
  def change
    create_table :c_pcard_relations do |t|
      t.integer :customer_id
      t.integer :package_card_id
      t.datetime :ended_at
      t.integer :status,:default=>0
      t.string :content
      t.decimal :price,:precision=>"20,2",:default=>0
      t.datetime :created_at
      t.integer :order_id
      t.integer :store_id
      
    end

    add_index :c_pcard_relations, :customer_id
    add_index :c_pcard_relations, :package_card_id
    add_index :c_pcard_relations, :status
    add_index :c_pcard_relations, :order_id
  end
end
