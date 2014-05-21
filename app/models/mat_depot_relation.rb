class MatDepotRelation < ActiveRecord::Base
  belongs_to :product
  belongs_to :depot
end
