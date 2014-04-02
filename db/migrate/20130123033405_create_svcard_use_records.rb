class CreateSvcardUseRecords < ActiveRecord::Migration
  #优惠卡使用表
  def change
    create_table :svcard_use_records do |t|
      t.integer :c_svc_relation_id
      t.integer :types
      t.float :use_price
      t.float :left_price
      t.string :content
      t.timestamps
    end

    add_index :svcard_use_records, :c_svc_relation_id
    add_index :svcard_use_records, :types
  end
end
