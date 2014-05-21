class ProductLoss < ActiveRecord::Base
  belongs_to :staff
  belongs_to :product
end