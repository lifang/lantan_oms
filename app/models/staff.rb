#encoding: utf-8
require 'fileutils'
class Staff < ActiveRecord::Base
  has_many :staff_role_relations, :dependent=>:destroy
  has_many :roles, :through => :staff_role_relations, :foreign_key => "role_id"
  has_many :salary_details
  has_many :work_records
  has_many :salaries
  has_many :station_staff_relations
  has_many :stations, :through => :station_staff_relations
  has_many :train_staff_relations
  has_many :violation_rewards
  has_many :staff_gr_records
  has_many :month_scores
  has_many :material_losses
  belongs_to :store
  has_many  :tech_orders
    
  #门店员工职务
  S_COMPANY = {:BOSS=>0,:CHIC=>2,:FRONT =>3,:TECHNICIAN =>1,:OTHER=>4} #0 老板 2 店长 3接待 1 技师 4其他
  N_COMPANY = {1=>"技师",3=>"接待",2=>"店长",4=>"其他"}
  LEVELS = {0=>"高级",1=>"中级",2=>"初级"}  #技师等级
  #总部员工职务
  STAFF_MENUS_AND_ROLES = {           #创建门店时创建的管理员将获取前台的所有权限
    :customers => 32767,
    :materials => 2147483647,
    :staffs => 65535,
    :datas => 524287,
    :stations => 3,
    :sales => 4194303,
    :base_datas => 16383,
    :pay_cash => 1,
    :finances => 1
  }

  STATUS = {:normal => 0, :afl => 1, :vacation => 2, :resigned => 3, :deleted => 4}
  VALID_STATUS = [STATUS[:normal], STATUS[:afl], STATUS[:vacation]]
  STATUS_NAME = {0 => "在职", 1 => "请假", 2 => "休假", 3 => "离职", 4 => "删除"}
  PerPage = 20
  scope :normal, where(:status => STATUS[:normal])
  scope :valid, where(:status => VALID_STATUS)
  scope :not_deleted, where("status != #{STATUS[:deleted]}")

  S_HEAD = {:BOSS=>0,:MANAGER =>2,:NORMAL=>1} #0老板 2 店长 1员工
  N_HEAD = {1=>"员工",0=>"老板", 2=>"店长"}
  WORKING_STATS = {:FORMAL => 1, :PROBATION => 0}   #在职状态 0试用 1正式
  S_WORKING_STATS = {1 => "正式", 0 => "实习"}
  IS_DEDUCT = {:YES => 1, :NO =>0} #是否参加提成，1是 0否
  S_IS_DEDUCT = {1 => "是", 0 => "否"}
  #教育程度
  N_EDUCATION = {0 => "研究生", 1 => "本科", 2 => "专科", 3 => "高中", 4 => "初中",
    5 => "小学", 6 => "无"}
  S_EDUCATION = {:GRADUATE => 0,  :UNIVERSITY => 1, :COLLEGE => 2, :SENIOR => 3, :JUNIOR => 4, :PRIMARY => 5, :NONE => 6}
  #员工性别
  N_SEX = {0 => "男", 1 => "女"}



  def has_password?(submitted_password)
		encrypted_password == encrypt(submitted_password)
	end

  def encrypt_password
    self.encrypted_password=encrypt(password)
  end


  private
  def encrypt(string)
    self.salt = make_salt if new_record?
    secure_hash("#{salt}--#{string}")
  end

  def make_salt
    secure_hash("#{Time.new.utc}--#{password}")
  end

  def secure_hash(string)
    Digest::SHA2.hexdigest(string)
  end

  def self.staff_and_order staff_id
    #本月完成订单数量和总金额
    stafforders = Order.find_by_sql("SELECT o.id,o.price from orders o where date_format(o.created_at,'%Y-%m')=date_format(now(),'%Y-%m') 
        and o.status in (#{Order::STATUS[:BEEN_PAYMENT]},#{Order::STATUS[:FINISHED]}) and o.front_staff_id = #{staff_id}")
    order_count = stafforders.length
    has_pay = stafforders.map(&:price).inject(0) { |sum,e| sum + e }

    #当前正在进行的订单
    order_now = Order.find_by_sql("SELECT o.id,o.code,cn.num,o.price sum_price from orders o INNER JOIN  car_nums cn on cn.id=o.car_num_id
        where date_format(o.created_at,'%Y-%m')=date_format(now(),'%Y-%m')
        and o.status in (#{Order::STATUS[:NORMAL]},#{Order::STATUS[:SERVICING]},#{Order::STATUS[:WAIT_PAYMENT]}) and o.front_staff_id = #{staff_id}")
    order_detail = OrderProdRelation.select("order_id,price,pro_num,total_price,t_price").
      where(["order_id in (1)", order_now.map(&:id)]).group_by{|order_pro| order_pro.order_id}
    orders_now = []
    order_now.each do |order|
      order_attr = order.attributes
      order_attr['detail'] = order_detail.present? && order_detail[order.id].present? ? order_detail[order.id] : []
      orders_now << order_attr
    end
    return [order_count,has_pay,orders_now]
  end
end
