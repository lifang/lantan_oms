#encoding: utf-8
class PackageCard < ActiveRecord::Base
  has_many :pcard_prod_relations
  has_many :pcard_material_relations
  has_many  :c_pcard_relations
  belongs_to :store

  STAT = {:INVALID =>0,:NORMAL =>1}  #0 为失效或删除  1 为正常使用
  TIME_SELCTED = {:PERIOD =>0,:END_TIME =>1} #0 时间段  1  有效时间长度
end
