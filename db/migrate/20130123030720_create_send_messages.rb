class CreateSendMessages < ActiveRecord::Migration
  #信息发送表
  def change
    create_table :send_messages do |t|
      t.integer :message_record_id  #发送的消息
      t.text :content
      t.integer :customer_id   #指定客户
      t.string :phone
      t.datetime :send_at
      t.integer :status, :default => 1
      t.integer :car_num_id
      t.integer :types, :default=>0
      t.integer :store_id

      t.timestamps
    end

    add_index :send_messages, :message_record_id
    add_index :send_messages, :status
  end
end
