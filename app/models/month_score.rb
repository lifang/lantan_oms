#encoding: utf-8
class MonthScore < ActiveRecord::Base
  belongs_to :staff
  belongs_to :store
  GOAL_NAME ={0=>"服务类",1=>"产品类",2=>"卡类",3=>"其他"}
  IS_UPDATE = {:YES=>1,:NO=>0} # 1 更新 0 未更新
end
