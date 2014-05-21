#encoding: utf-8
class ProdOrderType < ActiveRecord::Base
  belongs_to :product_order
end
