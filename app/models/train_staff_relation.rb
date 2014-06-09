#encoding: utf-8
class TrainStaffRelation < ActiveRecord::Base
  belongs_to :train
  belongs_to :staff

  STATUS = {:FAILED => 0, :SUCCESS => 1}    #是否通过考核 0没有 1有
end
