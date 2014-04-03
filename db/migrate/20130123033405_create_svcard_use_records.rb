class CreateSvcardUseRecords < ActiveRecord::Migration
  #优惠卡使用表
  def change
    create_table :svcard_use_records do |t|
      t.integer :c_svc_relation_id
      t.integer :types
      t.decimal :use_price,:default=>0,:precision=>"20,2"
      t.decimal :left_price,:default=>0,:precision=>"20,2"
      t.string :content
      t.datetime :created_at
      t.datetime :updated_at
	   t.timestamps
    end

    add_index :svcard_use_records, :c_svc_relation_id
    add_index :svcard_use_records, :types
	add_index :svcard_use_records, :created_at
  end
end
