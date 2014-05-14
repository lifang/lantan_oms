#encoding: utf-8
class Complaint < ActiveRecord::Base
  has_many :revisits 
  belongs_to :order
  belongs_to :customer
  belongs_to :store
  has_many :store_complaints
  has_many :store_pleasants
  require 'rubygems'
  require 'google_chart'
  require 'net/https'
  require 'uri'
  require 'open-uri'

  #投诉类型
  TYPES = {:CONSTRUCTION => 0, :SERVICE => 1, :PRODUCTION => 2, :INSTALLATION => 3, :ACCIDENT => 4, :OTHERS => 5, :INVALID => 6}
  TIMELY_DAY = 2 #及时解决的标准
  TYPES_NAMES = {0 => "施工质量", 1 => "服务质量", 2 => "产品质量", 3 => "门店设施", 4 => "意外事件", 5 => "其他", 6 => "无效投诉"}

  #投诉状态
  STATUS = {:UNTREATED => 0, :PROCESSED => 1} #0 未处理  1 已处理
  STATUS_NAME ={0 =>"未处理",1 =>"已处理"}
  VIOLATE = {:NORMAL=>1,:INVALID=>0} #0  不纳入  1 纳入
  VIOLATE_N = {true=>"是",false=>"否"}
  SEX = {:MALE =>1,:FEMALE =>0,:NONE=>2} # 0 未选择 1 男 2 女

  #获取用户的投诉
  def self.customer_complaints(store_id, customer_id, per_page, page)
    return Complaint.paginate_by_sql(["select c.id c_id, c.created_at, c.reason, c.suggestion, c.types, c.status, c.remark,
          st.name st_name1, st2.name st_name2, o.code, o.id o_id from complaints c
          left join orders o on o.id = c.order_id
          left join staffs st on st.id = c.staff_id_1 left join staffs st2 on st2.id = c.staff_id_2
          where c.store_id = ? and c.customer_id = ? ", store_id, customer_id],
      :per_page => per_page, :page => page)
    
  end

end
