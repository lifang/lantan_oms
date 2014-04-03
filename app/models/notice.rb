#encoding: utf-8
class Notice < ActiveRecord::Base
  belongs_to :store

  TYPES = {:BIRTHDAY => 0,  :URGE_GOODS => 1, :URGE_PAYMENT => 2,:IN => 3} # 0 客户生日 1 催货  2 催款 3到货未入库
  STATUS = {:NORMAL => false, :INVALID => true} # 0 有效提示  1 无效提示
end
