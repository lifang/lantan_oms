#encoding: utf-8
class CreateMenus < ActiveRecord::Migration
  #菜单表
  def change
    create_table :menus do |t|
      t.string :controller_name
      t.string :name
      t.timestamps
    end
    
  end
  
end
