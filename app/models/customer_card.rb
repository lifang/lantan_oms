#encoding: utf-8
class CustomerCard < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :sv_card
  STATUS = {:normal => 1, :cancel => 2} #0取消，1正常
  TYPES = {:STORED => 1, :DISCOUNT => 2,:PACKAGE => 3} #储值卡：1；打折卡：2；套餐卡：3
end
