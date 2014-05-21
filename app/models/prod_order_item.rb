#encoding: utf-8
class ProdOrderItem < ActiveRecord::Base
  belongs_to :product
  belongs_to :product_order
end
