class PcardMaterialRelation < ActiveRecord::Base
  belongs_to :package_card
  belongs_to :product
end
