class CreateMaterials < ActiveRecord::Migration
  #物料表
  def change
    create_table :materials do |t|
      t.string :name
      t.string :code  #物料编号
      t.float :price
      t.integer :storage  #库存量
      t.integer :types   #是否有库存
      t.boolean :status
      t.integer :store_id  #所属门店
      t.string :remark, :limit => 1000
      t.integer :check_num
      t.float :sale_price #零售价
      t.string :unit #单位
      t.boolean :is_ignore, :default => 0   #是否忽略，忽略后将不受门店门店库存预警值的影响,默认不忽略
      t.integer :material_low
      t.string :code_img
      t.integer :category_id
      t.decimal :import_price, :precision=>"20,2"
      t.boolean :create_prod, :defalut=>0
      
      t.timestamps
    end

    add_index :materials, :name
    add_index :materials, :types
    add_index :materials, :status
    add_index :materials, :store_id
  end
end
