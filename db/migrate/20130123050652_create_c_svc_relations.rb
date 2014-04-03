class CreateCSvcRelations < ActiveRecord::Migration
  #客户储值卡关系表
  def change
    create_table :c_svc_relations do |t|
      t.integer :customer_id
      t.integer :sv_card_id
      t.decimal :total_price,:default=>0,:precision=>"20,2"
      t.deciaml :left_price,:default=>0,:precision=>"20,2"
      t.string :id_card  #客户身份证
      t.boolean :is_billing,:default=>0  #是否已开据发票
      t.datetime :created_at
      t.string :verify_code
      t.integer :order_id
      t.boolean :status,:default=>0
      t.integer :return_types, :default=>0
      t.string :password
      t.integer :store_id
      
    end

    add_index :c_svc_relations, :customer_id
    add_index :c_svc_relations, :sv_card_id
  end
end
