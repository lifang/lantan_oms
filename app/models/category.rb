#encoding: utf-8
class Category < ActiveRecord::Base
  has_many :products
  TYPES = {:material => 0, :service => 1,:OWNER =>2,:ASSETS =>3}     #0物料或商品 1服务 3 付款类别 4 收款类别 5 资产类别
  TYPES_NAME = {0=>"物料/产品", 1=>"服务",2=>"收付款",3=>"资产"}
  DATA_TYPES = [TYPES[:good],TYPES[:service]]

  #业务开单查询类别
  SEARCH_ITEMS = {0=>"卡类",1=>"产品",2=>"服务"}
  ITEM_NAMES = {:CARD => 0,:PROD => 1,:SERVICE => 2}
end
