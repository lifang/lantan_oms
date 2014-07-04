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

  #pad端生成投诉
  def self.mk_record reason,request,store_id,order_id
    status = 1
    msg = 0
    begin
      order  = Order.find_by_id order_id
      staff_id_1 = order.cons_staff_id_1.nil? ? nil : order.cons_staff_id_1
      staff_id_2 = order.cons_staff_id_2.nil? ? nil : order.cons_staff_id_2
      Complaint.transaction do
        Complaint.create(:order_id => order_id, :customer_id => order.customer_id, :reason => reason,
          :suggestion => request, :status => STATUS[:UNTREATED], :store_id => store_id,:staff_id_1=>staff_id_1,
          :staff_id_2=>staff_id_2,:types => TYPES[:OTHERS],:is_violation=>VIOLATE[:INVALID], :code => make_code(store_id))
      end
    rescue
      status = 0
      msg = "数据错误!"
    end
    return [status, msg]
  end

  #获取用户的投诉
  def self.customer_complaints(store_id, customer_id, per_page, page)
    return Complaint.paginate_by_sql(["select c.id c_id, c.created_at, c.reason, c.suggestion, c.types, c.status, c.remark,
          st.name st_name1, st2.name st_name2, o.code, o.id o_id from complaints c
          left join orders o on o.id = c.order_id
          left join staffs st on st.id = c.staff_id_1 left join staffs st2 on st2.id = c.staff_id_2
          where c.store_id=? and c.customer_id=? order by c.created_at desc", store_id, customer_id],
      :per_page => per_page, :page => page)
  end

  def self.make_code store_id
    store = store_id.to_s
    if store_id.to_i < 10
      store = "00" + store_id.to_s
    elsif store_id.to_i >= 10 && store_id.to_i < 100
      store = "0" + store_id.to_s
    else
      store = store_id.to_s
    end
    code = store + Time.now.strftime("%Y%m%d%H%M%S")
    return code
  end
end
