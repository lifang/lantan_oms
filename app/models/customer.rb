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
  TYPES = { :NORMAL => 0, :GOOD => 1, :STRESS => 2} #1 一般客户  2 优质客户  3 重点客户
  C_TYPES = { 0 => "一般客户", 1 => "优质客户", 2 => "重点客户"}
  PROPERTY = {:PERSONAL => 0, :GROUP => 1}  #客户属性 0个人 1集团客户
  ALLOWED_DEBTS = {:NO => 0, :YES => 1}   #是否允许欠账
  CHECK_TYPE = {:MONTH => 0, :WEEK => 1}  #结算类型 按月/周结算
  

  def self.customer_valid car_nums, store_id, type, name, phone, id=nil    #新建或编辑客户时验证
    status = 1
    msg = ""
    if type==0  #新建
      cus = Customer.where(["name=? and status=? and store_id=?", name, STATUS[:NOMAL], store_id]).first
      if cus.nil?
        cus = Customer.where(["mobilephone=? and status=? and store_id=?", phone, STATUS[:NOMAL], store_id]).first
        if cus.nil?
          if car_nums.any?
            cus_car_nums = Customer.find_by_sql(["select cn.num nums from customers c inner join customer_num_relations
                cnr on c.id=cnr.customer_id inner join car_nums cn on cnr.car_num_id=cn.id
                where c.status=? and c.store_id=?", STATUS[:NOMAL], store_id]).map(&:nums)
            car_nums.each do |cn|
              if cus_car_nums.include?(cn)
                status = 0
                msg = "车牌号#{cn}已被注册!"
                break
              end
            end
          end
        else
          status = 0
          msg = "手机号已存在!"
        end
      else
        status = 0
        msg = "用户名已存在!"
      end
    elsif type ==1
      cus = Customer.where(["id!=? and name=? and status=? and store_id=?", id, name, STATUS[:NOMAL], store_id]).first
      if cus.nil?
        cus = Customer.where(["id!=? and mobilephone=? and status=? and store_id=?", id, phone, STATUS[:NOMAL], store_id]).first
        if cus.nil?
          if car_nums.any?
            cus_car_nums = Customer.find_by_sql(["select cn.num nums from customers c inner join customer_num_relations
                cnr on c.id=cnr.customer_id inner join car_nums cn on cnr.car_num_id=cn.id
                where c.status=? and c.store_id=?", STATUS[:NOMAL], store_id]).map(&:nums)
            car_nums.each do |cn|
              if cus_car_nums.include?(cn)
                status = 0
                msg = "车牌号#{cn}已被注册!"
                break
              end
            end
          end
        else
          status = 0
          msg = "手机号已存在!"
        end
      else
        status = 0
        msg = "用户名已存在!"
      end
    end
    return [status, msg]
  end

  def self.get_customer_tips store_id  #获取当前门店用户的投诉和通知
    complaints = Complaint.find_by_sql(["select c.id, c.reason, c.suggestion, o.code, cu.name, ca.num, cu.id cu_id, o.id o_id
      from complaints c inner join orders o on o.id = c.order_id
      inner join customers cu on cu.id = c.customer_id
      inner join car_nums ca on ca.id = o.car_num_id
      where c.store_id=? and c.status=? and cu.status=?", store_id, Complaint::STATUS[:UNTREATED],
        STATUS[:NOMAL]])
    cus_birthday_notices = Customer.find_by_sql(["select DISTINCT(c.id), c.name from customers c
      where c.status=? and c.store_id=? and c.birthday is not null and
      ((month(now())*30 + day(now()))-(month(c.birthday)*30 + day(c.birthday))) <= 0
      and ((month(now())*30 + day(now()))-(month(c.birthday)*30 + day(c.birthday))) > -7", Customer::STATUS[:NOMAL],
        store_id])
    return [complaints, cus_birthday_notices]
  end

  #验证用户和车的关系
  def Customer.create_single_cus(customer, carnum, phone, car_num, user_name, other_way,
      birth, buy_year, car_model_id, sex, address, is_vip, store_id)
    Customer.transaction do
      if customer.nil?
        customer = Customer.create(:name => user_name, :mobilephone => phone,
          :other_way => other_way, :birthday => birth, :status => Customer::STATUS[:NOMAL],
          :types => Customer::TYPES[:NORMAL], :username => user_name,
          :password => phone, :sex => sex, :address => address,:is_vip=>is_vip,:store_id=>store_id)
        customer.encrypt_password
        customer.save        
      end
      if carnum
        carnum.update_attributes(:buy_year => buy_year, :car_model_id => car_model_id)
      else
        carnum = CarNum.create(:num => car_num, :buy_year => buy_year,
          :car_model_id => car_model_id)
      end
      CustomerNumRelation.delete_all(["car_num_id = ?", carnum.id])
      CustomerNumRelation.create(:car_num_id => carnum.id, :customer_id => customer.id)
    end 
    return [customer, carnum]
  end
end
