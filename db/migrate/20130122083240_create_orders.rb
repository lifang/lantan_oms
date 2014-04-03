class CreateOrders < ActiveRecord::Migration
  def change
    create_table :orders do |t|
      t.string :code     #订单流水号
      t.integer :car_num_id  #车牌
      t.integer :status,:default=>0
      t.datetime :started_at
      t.datetime :ended_at
      t.decimal :price,:default=>0,:precision=>"20,2"
      t.boolean :is_visited,:default=>0  #是否回访
      t.integer :is_pleased,:default=>0  #是否满意 #3 不满意  2 一般  1 好  0 很好
      t.boolean :is_billing,:default=>0  #是否要发票
      t.integer :front_staff_id  #前台
      t.integer :cons_staff_id_1  #施工甲编号
      t.integer :cons_staff_id_2  #施工乙编号
      t.integer :station_id      #工位编号
      t.integer :sale_id,:default=>0         #参加活动
      t.string :c_pcard_relation_id  #套餐卡
      t.string :c_svc_relation_id    #优惠卡
      t.boolean :is_free,:default=>0      #是否免单
      t.integer :types       #订单的类型 产品、服务、套餐卡、打折卡、储值卡
      t.integer :store_id
      t.integer :customer_id
      t.datetime :auto_time
      t.decimal :front_deduct,:default=>0,:precision=>"20,2"
      t.decimal :technician_deduct,:default=>0,:precision=>"20,2"
      t.datetime :warn_time
      t.timestamps
    end

    add_index :orders, :code
    add_index :orders, :car_num_id
    add_index :orders, :status
    add_index :orders, :created_at
    add_index :orders, :front_staff_id
    add_index :orders, :cons_staff_id_1
    add_index :orders, :cons_staff_id_2
    add_index :orders, :station_id
    add_index :orders, :sale_id
    add_index :orders, :c_pcard_relation_id
    add_index :orders, :c_svc_relation_id
    add_index :orders, :store_id
    add_index :orders, :types
    add_index :orders, :is_visited
    add_index :orders, :customer_id
  end
end
