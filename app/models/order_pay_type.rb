#encoding: utf-8
class OrderPayType < ActiveRecord::Base
  belongs_to :order
  belongs_to :product
  PAY_TYPES = {:CASH => 0, :CREDIT_CARD => 1, :SV_CARD => 2, 
    :PACJAGE_CARD => 3, :SALE => 4, :IS_FREE => 5, :DISCOUNT_CARD => 6,:FAVOUR =>7,:CLEAR =>8,:HANG =>9} #0 现金  1 刷卡  2 储值卡   3 套餐卡  4  活动优惠  5免单
  PAY_TYPES_NAME = {0 => "现金", 1 => "银行卡", 2 => "储值卡", 3 => "套餐卡", 4 => "活动优惠", 5 => "免单", 6 => "打折卡",7=>"优惠",8=>"抹零",9=>"挂账"}
  LOSS = [PAY_TYPES[:SALE],PAY_TYPES[:DISCOUNT_CARD],PAY_TYPES[:FAVOUR],PAY_TYPES[:CLEAR]]
  PAY_STATUS = {:UNCOMPLETE =>1,:COMPLETE =>0} #1 挂账未结账  0  已结账
  FAVOUR = [PAY_TYPES[:SALE],PAY_TYPES[:IS_FREE],PAY_TYPES[:DISCOUNT_CARD],PAY_TYPES[:FAVOUR],PAY_TYPES[:CLEAR]]
  FINCANCE_TYPES = {0 => "现金", 1 => "银行卡", 2 => "储值卡", 3 => "套餐卡", 5 => "免单", 6 => "打折卡",9=>"挂账"}
    
end
