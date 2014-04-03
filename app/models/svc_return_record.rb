#encoding: utf-8
class SvcReturnRecord < ActiveRecord::Base
  belongs_to :store
  TYPES = {:IN => 0, :OUT => 1} #客户消费为支出=1   门店订货为收入=0
end
