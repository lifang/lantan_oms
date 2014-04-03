#encoding: utf-8
class Customer < ActiveRecord::Base
  has_many :customer_num_relations
  has_many :c_svc_relations
  has_many :c_pcard_relations
  has_many :revisits
  has_many :send_messages
  has_many :c_svc_relations
  has_many :reservations
  has_many :customer_store_relations
  has_many :stores, :through => :customer_store_relations
  attr_accessor :password
  validates :password, :allow_nil => true, :length =>{:within=>6..20, :message => "密码长度必须在6-20位之间"}

  #客户状态
  STATUS = {:NOMAL => 0, :DELETED => 1} #0 正常  1 删除
  #客户类型
  IS_VIP = {:NORMAL => 0, :VIP => 1} #0 常态客户 1 会员卡客户
  TYPES = {:GOOD => 0, :NORMAL => 1, :STRESS => 2} #1 优质客户  2 一般客户  3 重点客户
  C_TYPES = {0 => "优质客户", 1 => "一般客户", 2 => "重点客户"}
  RETURN_REASON = { 0 => "质量问题", 1 => "服务态度", 2 => "拍错买错",3 => "效果不好，不喜欢",4 => "操作失误", 5 => "其他"}
  PROPERTY = {:PERSONAL => 0, :GROUP => 1}  #客户属性 0个人 1集团客户
  ALLOWED_DEBTS = {:NO => 0, :YES => 1}   #是否允许欠账
  CHECK_TYPE = {:MONTH => 0, :WEEK => 1}  #结算类型 按月/周结算
  
end
