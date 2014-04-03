#encoding: utf-8
class GoalSale < ActiveRecord::Base
  belongs_to :store
  has_many :goal_sale_types
  TYPES_NAMES = {0 =>"产品",1 =>"服务",2 =>"卡",3 =>"其他"}
  TYPES = {:PRODUCT =>0,:SERVICE =>1,:CARD =>2,:OTHER =>3}
  
end
