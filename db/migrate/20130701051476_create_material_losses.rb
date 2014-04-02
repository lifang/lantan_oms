class CreateMaterialLosses < ActiveRecord::Migration
  def change
    create_table :material_losses do |t|
      t.integer :loss_num #报损数量
      t.integer :staff_id #报损人
      t.integer :store_id  #所属门店
      t.integer :material_id
      t.timestamps
    end

    add_index :material_losses, :staff_id
    add_index :material_losses, :material_id
  end
end
