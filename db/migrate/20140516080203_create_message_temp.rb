class CreateMessageTemp < ActiveRecord::Migration
  #短信模板
  def change
    create_table :message_temps do |t|
      t.integer :types  #类型
      t.string :content #内容
      t.integer :store_id
      t.timestamps
    end
  end
end
