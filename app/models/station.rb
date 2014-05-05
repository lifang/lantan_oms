#encoding: utf-8
class Station < ActiveRecord::Base
  has_many :word_orders
  has_many :station_staff_relations
  has_many :staffs, :through => :station_staff_relations
  has_many :station_service_relations
  has_many :wk_or_times
  has_many :products, :through => :station_service_relations
  belongs_to :store
  has_many :equipment_infos
  STAT = {:WRONG =>0,:NORMAL =>2,:LACK =>1,:NO_SERVICE =>3, :DELETED => 4} #0 故障 1 缺少技师 2 正常 3 无服务 4删除
  STAT_NAME = {0=>"故障",1=>"缺少技师",2=>"正常",3=>"缺少服务项目"}
  VALID_STATUS = [STAT[:WRONG], STAT[:NORMAL], STAT[:LACK], STAT[:NO_SERVICE]]
  scope :can_show, where(:status => VALID_STATUS)
  IS_CONTROLLER = {:YES=>1,:NO=>0} #定义是否拥有工控机
  PerPage = 10
  validates :name, :presence => true

end
