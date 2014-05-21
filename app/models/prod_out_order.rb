#encoding: utf-8
class ProdOutOrder < ActiveRecord::Base
  belongs_to :product
  belongs_to :product_order
  TYPES = {0 => "消耗", 1 => "调拨", 2 => "赠送", 3 => "销售"}
  TYPES_VALUE = {:cost => 0, :transfer => 1, :send => 2, :sale => 3}
  
end
