#encoding: utf-8
class WorkRecord < ActiveRecord::Base
  belongs_to :staff
  ATTEND_TYPES = {:ATTEND =>0,:LATE =>1,:EARLY =>2,:LEAVE =>3,:ABSENT =>4}
  ATTEND_NAME = {0=>"出勤",1=>"迟到",2=>"早退",3=>"请假",4=>"旷工"}
  ATTEND_YES =[ATTEND_TYPES[:ATTEND],ATTEND_TYPES[:LATE],ATTEND_TYPES[:EARLY]]

end
