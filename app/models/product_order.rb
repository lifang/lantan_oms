#encoding: utf-8
require 'date'
class ProductOrder < ActiveRecord::Base
  has_many :prod_order_items
  has_many :prod_out_orders
  has_many  :prod_in_orders
  has_many  :prod_order_types
  has_many :products, :through => :prod_order_items
  belongs_to :supplier

  STATUS = {:no_pay => 0, :pay => 1, :cancel => 4}
  S_STATUS = { 0 => "未付款", 1 => "已付款", 4 => "已取消"}
  M_STATUS = {:no_send => 0, :send => 1, :received => 2, :save_in => 3, :returned => 4} #0未发货，1已发货，2已收货，3已入库，4已退货
  S_M_STATUS = { 0 => "未发货", 1 => "已发货", 2 => "已收货", 3 => "已入库", 4 => "已退货"}
  PAY_TYPES = {:CHARGE => 1, :SAV_CARD => 2, :CASH => 3, :STORE_CARD => 4, :SALE_CARD => 5}
  PAY_TYPE_NAME = {1 => "支付宝",2 => "储值卡", 3 => "现金", 4 => "门店账户扣款", 5 => "活动优惠"}

  #生成订单号
  def self.material_order_code(store_id, time=nil)
    store = store_id.to_s
    if store_id < 10
      store =   "00" + store_id.to_s
    elsif store_id < 100
      store =    "0" + store_id.to_s
    end
    store + (time.nil? ? Time.now.strftime("%Y%m%d%H%M%S") : DateTime.parse(time).strftime("%Y%m%d%H%M%S"))
  end

end
