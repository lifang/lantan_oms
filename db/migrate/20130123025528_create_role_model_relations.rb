class CreateRoleModelRelations < ActiveRecord::Migration
  #权限功能表
  def change
    create_table :role_model_relations do |t|
      t.integer :role_id
      t.integer :num
      t.string :model_name
      t.integer :store_id
      t.bigint :num
      t.timestamps
    end

    add_index :role_model_relations, :role_id
  end
end
