#encoding: utf-8
require 'date'
class MaterialOrder < ActiveRecord::Base
  has_many :mat_order_items
  has_many :mat_out_orders
  has_many  :mat_in_orders
  has_many  :m_order_types
  has_many :materials, :through => :mat_order_items
  belongs_to :supplier

  STATUS = {:no_pay => 0, :pay => 1, :cancel => 4}
  S_STATUS = { 0 => "未付款", 1 => "已付款", 4 => "已取消"}
  M_STATUS = {:no_send => 0, :send => 1, :received => 2, :save_in => 3, :returned => 4} #0未发货，1已发货，2已收货，3已入库，4已退货
  S_M_STATUS = { 0 => "未发货", 1 => "已发货", 2 => "已收货", 3 => "已入库", 4 => "已退货"}
  PAY_TYPES = {:CHARGE => 1, :SAV_CARD => 2, :CASH => 3, :STORE_CARD => 4, :SALE_CARD => 5}
  PAY_TYPE_NAME = {1 => "支付宝",2 => "储值卡", 3 => "现金", 4 => "门店账户扣款", 5 => "活动优惠"}

end
