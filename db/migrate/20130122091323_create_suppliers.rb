class CreateSuppliers < ActiveRecord::Migration
  #供应商
  def change
    create_table :suppliers,:options => 'AUTO_INCREMENT = 1001' do |t|
      t.string :name
      t.string :email
      t.string :phone
      t.string :address
      t.string :contact  #联系人
      t.integer :store_id
      t.integer :status
      t.integer :check_type
      t.integer :check_time
      t.string :cap_name
      t.timestamps
    end

    add_index :suppliers, :created_at
  end
end
