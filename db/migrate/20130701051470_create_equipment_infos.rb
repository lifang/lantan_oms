class CreateEquipmentInfos < ActiveRecord::Migration
  def change
    create_table :equipment_infos do |t|
      t.integer :store_id
      t.integer :current_day
      t.integer :num
      t.integer :station_id

      t.timestamps
    end
    add_index :equipment_infos, :store_id
    add_index :equipment_infos, :station_id
  end
end
