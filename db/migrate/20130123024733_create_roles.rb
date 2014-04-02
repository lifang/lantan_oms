#encoding: utf-8
class CreateRoles < ActiveRecord::Migration
  def change
    create_table :roles do |t|
      t.string :name
      t.integer :store_id
      t.integer :role_type
      
      t.timestamps
    end
  end
end
