#encoding: utf-8
class SalaryDetail < ActiveRecord::Base
  belongs_to :staff
  belongs_to  :violation_reward

  BASE_SCORE = {:SCORE => 90} #90分为标准分，90分以下每低一份按基本工资的百分之一计算

end
