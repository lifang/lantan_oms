class CreateSvCards < ActiveRecord::Migration
  #打折卡
  def change
    create_table :sv_cards do |t|
      t.string :name
      t.string :img_url
      t.integer :types
     # t.float :discount #折扣比例 已经改成
      t.string :description
      t.integer :store_id
      t.integer :use_range    #优惠卡使用范围
      t.integer :status, :default => 0
      t.decimal :price, :precision=>"20,2",:default=>0
      
      t.timestamps
    end

    add_index :sv_cards, :types
  end
end
