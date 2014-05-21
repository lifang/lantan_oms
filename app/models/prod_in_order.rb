#encoding: utf-8
class ProdInOrder < ActiveRecord::Base
  belongs_to :product
  belongs_to :product_order
  belongs_to :staff

end
