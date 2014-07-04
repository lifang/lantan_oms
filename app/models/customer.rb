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
  def Customer.create_single_cus(customer,carnum,mobilephone,car_num,name,buy_year,car_model_id,sex,store_id,distance)
    Customer.transaction do
      if customer.nil?
        customer = Customer.create(:name => name, :mobilephone => mobilephone,:status => Customer::STATUS[:NOMAL],
          :types => Customer::TYPES[:NORMAL], :username => name,:password => mobilephone, :sex => sex,:store_id=>store_id)
        customer.encrypt_password
        customer.save        
      end
      if carnum
        carnum.update_attributes(:buy_year => buy_year, :car_model_id => car_model_id,:distance=>distance)
      else
        carnum = CarNum.create(:num => car_num, :buy_year => buy_year,
          :car_model_id => car_model_id,:distance=>distance)
      end
      CustomerNumRelation.delete_all(["car_num_id = ?", carnum.id])
      CustomerNumRelation.create(:car_num_id => carnum.id, :customer_id => customer.id)
    end 
    return [customer, carnum]
  end


  #获取某个用户的所有储值卡
  def self.get_customer_sv_cards customer_id
    sv_cards_arr = []
    sv_cards = CustomerCard.find_by_sql(["select sv.apply_content, sv.description, cc.amt, cc.id,
          sv.name,sv.totle_price from customer_cards cc inner join sv_cards sv
         on cc.card_id=sv.id where cc.customer_id=? and cc.types=? and cc.status=?", customer_id,
        CustomerCard::TYPES[:STORED], CustomerCard::STATUS[:normal]])
    sv_cards.each do |sc|
      hash = {:description => sc.description, :id => sc.id, :name => sc.name,
        :totle_price => sc.totle_price.to_f.round(2), :left_price => sc.amt.to_f.round(2)}
      prods = Product.where(["id in (?)", sc.apply_content.split(",").collect{|e|e.to_i}]) if sc.apply_content && sc.apply_content!=""
      hash[:apply_content] = prods && prods.any? ? prods.map(&:name).join(",") : ""
      use_records = SvcardUseRecord.where(["customer_card_id=?", sc.id]).order("created_at desc")
      records = []
      use_records.each do |ur|
        record_hash = {:created_at => ur.created_at.strftime("%Y-%m-%d %H:%M"), :customer_card_id => sc.id,
          :left_price => ur.left_price.to_f.round(2), :use_price => ur.use_price.to_f.round(2), :types => ur.types}
        record_hash[:items] = ur.content
        records << record_hash
      end if use_records.any?
      hash[:records] = records
      hash[:last_time] = use_records.any? ? use_records[0].created_at.strftime("%Y-%m-%d %H:%M") : ""
      sv_cards_arr << hash
    end if sv_cards.any?
    return sv_cards_arr
  end

  #获取某个用户的所有打折卡
  def self.get_customer_dis_cards customer_id
    dis_cards = []
    cus_dis_cards = CustomerCard.find_by_sql(["select sv.apply_content, sv.description, sv.date_month, cc.discount, cc.id,
          cc.ended_at, sv.name,sv.totle_price from customer_cards cc inner join sv_cards sv
         on cc.card_id=sv.id where cc.customer_id=? and cc.types=? and cc.status=?", customer_id,
        CustomerCard::TYPES[:DISCOUNT], CustomerCard::STATUS[:normal]])
    cus_dis_cards.each do |dc|
      hash = {:description => dc.description, :date_month => dc.date_month,
        :discount => dc.discount, :id => dc.id, :ended => dc.ended_at.nil? ? "" : dc.ended_at.strftime("%Y-%m-%d"),
        :name => dc.name, :totle_price => dc.totle_price}
      prods = Product.where(["id in (?)", dc.apply_content.split(",").collect{|e|e.to_i}]) if dc.apply_content && dc.apply_content!=""
      hash[:apply_content] = prods && prods.any? ? prods.map(&:name).join(",") : ""
      dis_cards << hash
    end if cus_dis_cards.any?
    return dis_cards
  end

  #获取某个用户的所有套餐卡
  def self.get_customer_package_cards customer_id
    cus_pk_cards = []
    svcards = CustomerCard.find_by_sql(["select cc.id, cc.package_content, cc.ended_at, pc.id pcid, pc.name
              from customer_cards cc inner join package_cards pc on cc.card_id=pc.id
              where cc.customer_id=? and cc.types=? and cc.status=?", customer_id, CustomerCard::TYPES[:PACKAGE],
        CustomerCard::STATUS[:normal]])

    svcards.each do |sv|
      pc_hash = {:id => sv.id, :name => sv.name, :ended_at => sv.ended_at.nil? ? "" : sv.ended_at.strftime("%Y-%m-%d"), :is_new => 0}
      pc_prods = []
      sv.package_content.split(",").each do |ele| #1-xxx-22次,...
        prod_num = PcardProdRelation.find_by_product_id_and_package_card_id(ele.split("-")[0].to_i, sv.pcid)
        types, storage = Product.get_prod_type_and_storage(ele.split("-")[0].to_i)
        pc_prod_hash = {:id => ele.split("-")[0], :name => ele.split("-")[1], :product_num => prod_num.product_num.to_i,
          :unused_num => ele.split("-")[2].to_i, :selected_num => 0, :storage => storage, :types => types}
        pc_prods << pc_prod_hash
      end if sv.package_content && sv.package_content!=""

      pc_hash[:products] = pc_prods
      cus_pk_cards << pc_hash
    end if svcards.any?
    return cus_pk_cards
  end

  #查看该客户某辆车正在消费的订单
  def  self.get_customer_working_orders customer_id, car_num_id
    array = []
    working_orders = Order.find_by_sql(["select o.car_num_id,o.code,o.created_at,o.id oid,o.price,o.status,
        s1.name sname1,s2.name sname2,s3.name front_name from orders o
        left join staffs s1 on o.cons_staff_id_1=s1.id
        left join staffs s2 on o.cons_staff_id_2=s2.id
        left join staffs s3 on o.front_staff_id=s3.id
        where o.status in (?) and o.car_num_id=? and o.customer_id=? order by o.created_at desc",
        [Order::STATUS[:NORMAL], Order::STATUS[:SERVICING], Order::STATUS[:WAIT_PAYMENT],Order::STATUS[:BEEN_PAYMENT]],
        car_num_id, customer_id])

    working_orders.each do |wo|
      hash = {:car_num_id => wo.car_num_id, :code => wo.code, :created_at => wo.created_at.strftime("%Y-%m-%d %H:%M"),
        :id => wo.oid, :name => wo.front_name, :price => wo.price.to_f.round(2),
        :staff_name => "#{wo.sname1}, #{wo.sname2}"}
      w_order = WorkOrder.find_by_order_id(wo.oid)
      if w_order
        if wo.status!= Order::STATUS[:BEEN_PAYMENT]#订单返回给前段时状态的意义： 0等待施工 1正在施工 2等待付款
          hash[:status] = wo.status
        else
          if w_order.status == WorkOrder::STAT[:WAIT]  #3已付款未施工 4已付款正在施工
            hash[:status] = 3
          elsif w_order.status == WorkOrder::STAT[:SERVICING]
            hash[:status] = 4
          end
        end
      else
        hash[:status] = 5   #该订单只买了卡类、产品 未买服务    如果是买的卡类或者产品 order的status永远不会等于3
      end
      prod_arr = []
      order_servs = OrderProdRelation.find_by_sql(["select opr.price, opr.pro_num, opr.total_price, p.name
          from order_prod_relations opr inner join products p on opr.item_id=p.id
          where opr.order_id=? and opr.prod_types=?", wo.oid, OrderProdRelation::PROD_TYPES[:SERVICE]])
      order_pcards = OrderProdRelation.find_by_sql(["select opr.price, opr.pro_num, opr.total_price, p.name
          from order_prod_relations opr inner join package_cards p on opr.item_id=p.id
          where opr.order_id=? and opr.prod_types=?", wo.oid, OrderProdRelation::PROD_TYPES[:P_CARD]])
      order_svcards = OrderProdRelation.find_by_sql(["select opr.price, opr.pro_num, opr.total_price, p.name
          from order_prod_relations opr inner join package_cards p on opr.item_id=p.id
          where opr.order_id=? and opr.prod_types=?", wo.oid, OrderProdRelation::PROD_TYPES[:SV_CARD]])
      order_servs.each do |os|
        prod_hash = {:name => os.name, :price => os.price.to_f.round(2), :pro_num => os.pro_num.to_f.round(2),
          :total_price => os.total_price.to_f.round(2)}
        prod_arr << prod_hash
      end if order_servs.any?
      order_pcards.each do |op|
        prod_hash = {:name => op.name, :price => op.price.to_f.round(2), :pro_num => op.pro_num.to_f.round(2),
          :total_price => op.total_price.to_f.round(2)}
        prod_arr << prod_hash
      end if order_pcards.any?
      order_svcards.each do |os|
        prod_hash = {:name => os.name, :price => os.price.to_f.round(2), :pro_num => os.pro_num.to_f.round(2),
          :total_price => os.total_price.to_f.round(2)}
        prod_arr << prod_hash
      end if order_svcards.any?
      hash[:products] = prod_arr
      array << hash
    end if working_orders.any?

    return array
  end

  #查看该客户某辆车的消费记录
  def self.get_customer_order_records customer_id, car_num_id
    array = []
    working_orders = Order.find_by_sql(["select o.id, o.code, o.status, o.created_at, o.price, s1.name front_name,
          s2.name staff_name1, s3.name staff_name2 from orders o inner join car_nums cn on o.car_num_id=cn.id
          left join staffs s1 on o.front_staff_id=s1.id
          left join staffs s2 on o.cons_staff_id_1=s2.id
          left join staffs s3 on cons_staff_id_2=s3.id
          where o.car_num_id=? and o.customer_id=? and o.status=? order by o.created_at desc", car_num_id,
        customer_id, Order::STATUS[:FINISHED]])
    working_orders.each do |wo|
      hash = {:car_num_id => car_num_id, :code => wo.code, :created_at => wo.created_at.strftime("%Y-%m-%d %H:%M"),
        :id => wo.id, :name => wo.front_name, :price => wo.price.to_f.round(2), :staff_name => "#{wo.staff_name1},#{wo.staff_name2}",
        :status => wo.status}
      order_prods = OrderProdRelation.find_by_sql(["select opr.price, opr.pro_num, opr.total_price, p.name
          from order_prod_relations opr inner join products p on opr.item_id=p.id
          where opr.order_id=? and opr.prod_types=?", wo.id, OrderProdRelation::PROD_TYPES[:SERVICE]])
      prod_arr = []
      order_prods.each do |op|
        prod_hash = {:name => op.name, :price => op.price.to_f.round(2), :pro_num => op.pro_num.to_f.round(2),
          :total_price => op.total_price.to_f.round(2)}
        prod_arr << prod_hash
      end
      hash[:products] = prod_arr
      array << hash
    end if working_orders.any?
    return array
  end

end
