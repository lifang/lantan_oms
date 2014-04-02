#encoding: utf-8
class CreateMenus < ActiveRecord::Migration
  #菜单表
  def change
    create_table :menus do |t|
      t.string :controller
      t.string :name
      t.timestamps
    end
    add_index :menus, :controller
    
  end
  
end
