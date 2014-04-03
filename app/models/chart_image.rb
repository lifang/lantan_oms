#encoding: utf-8
require 'google_chart'
require 'net/https'
require 'uri'
require 'open-uri'
class ChartImage < ActiveRecord::Base
  # 0 满意度 1 投诉统计 2 技师平均水平 3 前台平均水平 4 员工绩效
  TYPES = {:SATIFY =>0,:COMPLAINT =>1,:MECHINE_LEVEL =>2,:FRONT_LEVEL =>3,:STAFF_LEVEL =>4}

end
