#encoding: utf-8
class Revisit < ActiveRecord::Base
  belongs_to :customer
  has_many :revisit_order_relations
  belongs_to :complaint

  TYPES = {:SHOPPING => 0, :COMPLAINT => 1, :OTHER => 3} #回访类别
  TYPES_NAME = {0 => "消费回访", 1 => "投诉回访", 2 => "其他"}
  
end
