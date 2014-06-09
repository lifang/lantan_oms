#encoding: utf-8
class ViolationReward < ActiveRecord::Base
  belongs_to :staff
  has_many :salary_details

  #process_type 奖励、惩罚方法
  VIOLATE = {:deducate =>1,:cut=>2,:decrease=>3,:fire=>4} #1 扣考核分 2 扣款 3 降级 4 辞退 
  N_VIOLATE = {1 => "扣考核分", 2 => "扣款", 3 => "降级", 4 => "辞退"}
  REWARD = {:reward =>1,:salary=>2,:reduce=>3,:vocation=>4} #1 奖金 2 加薪 3 缩短升值期限 4 带薪假期
  N_REWARD = {1 => "奖金", 2 => "加薪", 3 => "缩短升值期限", 4 => "带薪假期"}
  
  #belong_types 奖励、惩罚类别
  TYPES_NAMES = {:SERVICE=>0,:SPOT=>1,:RUN=>2,:MANAGE=>3,:HARD=>4}
  VIOLATE_TYPES = {0=>"服务",1 => "现场", 2 => "运营", 3 => "人事", 4 => "绩效"}

  TYPES = {:VIOLATION => 0, :REWARD => 1} #0 处罚  1 奖励

  STATUS = {:NOMAL => 0, :PROCESSED => 1} #0 未处理  1 已处理

end
