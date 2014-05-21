class DeleteTableMaterials < ActiveRecord::Migration
  def change
    drop_table :materials
    drop_table :material_losses
    drop_table :material_orders
    drop_table :mat_order_items
    drop_table :mat_in_orders
    drop_table :mat_out_orders
    drop_table :m_order_types
    drop_table :products

    create_table :products do |t|
      t.string :name    #名称
      t.string :code    #条形码
      t.decimal :base_price, :precision=>"20,2", :default=>0 #零售价
      t.decimal :sale_price, :precision=>"20,2", :default=>0 #促销价
      t.decimal :t_price, :precision=>"20,2", :default => 0  #成本价
      t.string :description   #产品介绍
      t.text :introduction  #产品描述
      t.string :remark  #备注
      t.integer :types  #物料、产品、服务
      t.string :service_code   #服务代码
      t.boolean :status, :default => true     #状态
      t.boolean :is_shelves, :default => false #是否上架销售
      t.boolean :is_service   #判断是产品还是服务
      t.integer :staff_level   #所需技师等级
      t.integer :staff_level_1
      t.string :img_url #图片
      t.integer :cost_time   #花费时长
      t.integer :store_id
      t.string :standard #规格
      t.string :unit #单位
      t.decimal :storage, :precision=>"20,2", :default => 0 #库存量
      t.decimal :check_num, :precision=>"20,2", :default => 0 #盘点数量
      t.decimal :low_warning, :precision=>"20,2", :default => 0 #库存预警
      t.boolean :is_ignore, :default => false #是否忽略
      t.boolean :is_auto_revist #是否自动回访
      t.integer :auto_time
      t.text :revist_content  #回访内容
      t.integer :prod_point   #产品积分
      t.boolean :show_on_ipad, :default => true #判断服务是否在ipad端显示
      t.boolean :commonly_used, :default => false  #给服务加标志，服务是否在新的下单系统中显示
      t.integer :category_id  #所属类别
      t.boolean :is_added, :default=>false #是否施工
      t.decimal :deduct_percent, :precision=>"20,2", :default=>0   #销售提成百分比
      t.decimal :deduct_price, :precision=>"20,2", :default=>0 #销售提成金额
      t.decimal :techin_price, :precision=>"20,2", :default=>0  #技师提成百分比
      t.decimal :techin_percent, :precision=>"20,2", :default=>0 #技师提成金额
      t.integer :single_types, :defalut=>0  #是否是套装产品
      t.timestamps
    end

    create_table :product_losses do |t|   #库存报损表
      t.integer :product_id
      t.decimal :loss_num, :precision=>"20,2"   #报损数目
      t.integer :staff_id  #报损人
      t.integer :store_id
      t.timestamps
    end

    create_table :product_orders do |t|   #订货记录
      t.string :code    #订单号
      t.integer :supplier_id  #供货商编号
      t.integer :supplier_type  #供货类型
      t.integer :status
      t.integer :staff_id
      t.decimal :price, :precision=>"20,2"
      t.datetime :arrival_at   #到达日期
      t.string :logistics_code  #物流单号
      t.string :carrier     #托运人姓名
      t.integer :store_id
      t.string :remark
      t.integer :sale_id #活动代码对应的活动
      t.integer :m_status #物流订单状态
      t.timestamps
    end

    create_table :prod_order_items do |t|   #物料订货详情
      t.integer :product_order_id
      t.integer :product_id
      t.decimal :product_num, :precision=>"20,2"
      t.decimal :price, :precision=>"20,2"
      t.timestamps
    end

    create_table :prod_in_orders do |t|   #物料订货详情
      t.integer :product_order_id
      t.integer :product_id
      t.decimal :product_num, :precision=>"20,2"
      t.decimal :price, :precision=>"20,2"
      t.integer :staff_id
      t.timestamps
    end

    create_table :prod_out_orders do |t|   #物料订货详情
      t.integer :product_id
      t.integer :staff_id
      t.decimal :product_num, :precision=>"20,2"
      t.decimal :price, :precision=>"20,2"
      t.integer :product_order_id
      t.integer :types, :limit => 1 #出库类型
      t.integer :store_id
      t.timestamps
    end

    create_table :prod_order_types do |t|   #物料支付类型表
      t.integer :product_order_id  #所需物料订单编号
      t.integer :pay_types
      t.decimal :price, :precision=>"20,2"
      t.timestamps
    end
    add_index :products, :name
    add_index :products, :types
    add_index :products, :status
    add_index :products, :is_service
    add_index :products, :store_id
    add_index :product_losses, :staff_id
    add_index :product_losses, :product_id
    add_index :product_orders, :code
    add_index :product_orders, :supplier_id
    add_index :product_orders, :supplier_type
    add_index :product_orders, :status
    add_index :product_orders, :staff_id
    add_index :product_orders, :store_id
    add_index :product_orders, :sale_id
    add_index :product_orders, :m_status
    add_index :prod_order_items, :product_order_id
    add_index :prod_order_items, :product_id
    add_index :prod_in_orders, :product_order_id
    add_index :prod_in_orders, :product_id
    add_index :prod_in_orders, :staff_id
    add_index :prod_out_orders, :product_id
    add_index :prod_out_orders, :staff_id
    add_index :prod_out_orders, :product_order_id
    add_index :prod_order_types, :product_order_id
    add_index :prod_order_types, :pay_types
  end

end
