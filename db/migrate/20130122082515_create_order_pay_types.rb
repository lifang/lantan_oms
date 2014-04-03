class CreateOrderPayTypes < ActiveRecord::Migration
  #订单付款方式
  def change
    create_table :order_pay_types do |t|
      t.integer :order_id  #订单编号
      t.integer :pay_type  #付款方式
      t.decimal :price,:precision=>"20,2",:default=>0
      t.integer :product_id #订单付款是为哪一项付款
      t.datetime :created_at
      t.integer :product_num  #只对套餐卡有用，记录套餐卡优惠的商品的个数
      t.integer :pay_cash, :default=>0
      t.string :second_parm, :default=>0
      t.integer :pay_status, :default=>0
    end

    add_index :order_pay_types, :order_id
    add_index :order_pay_types, :pay_type
  end
end
