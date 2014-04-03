class CreateStores < ActiveRecord::Migration
  #门店表
  def change
    create_table :stores do |t|
      t.string :name
      t.string :address
      t.string :phone
      t.string :contact   #门店联系人
      t.string :email
      t.string :position   #门店坐标
      t.string :introduction #门店介绍
      t.string :img_url
      t.datetime :opened_at
      t.decimal :account,:precision=>"20,2",:default=>0  #门店账户余额
      t.integer :city_id
      t.integer :status,:default=>0
      t.string :code
      t.integer :edition_lv     #门店使用的系统的版本等级
      t.string :limited_password
      t.integer :cash_auth, :default => 0 #该门店是否有在pad上收银的权限
      t.integer :auto_send, :default=>1
      t.boolean :is_chain,:default=>0
      
      t.timestamps
    end

    add_index :stores, :created_at
    add_index :stores, :city_id
    add_index :stores, :status
    add_index :stores, :code
    add_index :stores, :edition_lv
  end
end
