class CreateSvcReturnRecords < ActiveRecord::Migration
  #储值卡返还表
  def change
    create_table :svc_return_records do |t|
      t.integer :store_id
      t.decimal :price,:default=>0,:precision=>"20,2"
      t.integer :types
      t.text :content 
      t.integer :target_id
      t.decimal :total_price,:default=>0,:precision=>"20,2"

      t.datetime :created_at
    end

    add_index :svc_return_records, :store_id
    add_index :svc_return_records, :created_at
  end
end
