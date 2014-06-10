#encoding: utf-8
class OrderProdRelation < ActiveRecord::Base
  belongs_to :order
  belongs_to :product

  PROD_TYPES = {:SERVICE => 1, :CARD => 2} #产品服务：1，卡类：2
  
end
