#encoding: utf-8
class OrderProdRelation < ActiveRecord::Base
  belongs_to :order
  belongs_to :product

  PROD_TYPES = {:SERVICE => 1, :P_CARD => 2, :SV_CARD => 3} #1产品或服务, 2套餐卡, 3储值卡、打折卡
  
end
