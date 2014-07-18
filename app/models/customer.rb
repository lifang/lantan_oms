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
                where c.status=? and c.store_id=? and c.id!=?", STATUS[:NOMAL], store_id, id]).map(&:nums)
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
      pc_hash = {:id => sv.pcid, :cus_card_id => sv.id, :name => sv.name, :ended_at => sv.ended_at.nil? ? "" : sv.ended_at.strftime("%Y-%m-%d"), :is_new => 0}
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
        customer_id, Order::STATUS[:BEEN_PAYMENT]])
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

  #客户下单 生成记录并排单
  def self.make_order customer_id, car_num_id, store_id, staff_id, prods
    #type:0-产品  1-服务  2－打折卡  3－套餐卡  4-储值卡
    #0_id_count
    #1_id_count
    #2_id_isNew
    #3_id_isNew(新买的套餐卡)
    #4_id_isNew_password
    #3_id_isNew_proId=num(用的自己的套餐卡下单)
    order = Order.create(:code => Order.make_code(store_id), :car_num_id => car_num_id, :status => Order::STATUS[:NORMAL],
      :is_visited => false, :is_billing => false, :front_staff_id => staff_id, :store_id => store_id,
      :customer_id => customer_id)
    prod_ids_array = []   #该订单中所买的产品和服务的id
    by_pcard_buy = []  #记录订单中的通过套餐卡下单的产品或服务的数量
    prods_and_cards = [] #该订单中所买的产品、服务和卡类的详细信息
    oder_total_price = 0 #订单总价
    actual_price = 0 #实际需要付款的钱(通过套餐卡下单的价格不算)
    work_order_hash = {}  #需要创建工单的服务或者产品
    prods.each do |prod|
      type = prod.split("_")[0].to_i
      id = prod.split("_")[1].to_i
      case type
      when 0 #是产品
        #如果买的数量不为零则创建order_prod_relations(有可能为零)
        if prod.split("_")[2].to_i != 0
          product = Product.find_by_id(id)
          OrderProdRelation.create(:order_id => order.id, :item_id => id, :pro_num => prod.split("_")[2].to_i,
            :price => product.sale_price.to_f.round(2),
            :total_price => (product.sale_price.to_f.round(2) * prod.split("_")[2].to_i).round(2),
            :t_price => product.base_price.to_f.round(2), :prod_types => OrderProdRelation::PROD_TYPES[:SERVICE])
          #如果是需要施工的产品 则要加到创建工单的hash里去
          if product.is_added
            if work_order_hash[product.id]
              work_order_hash[product.id] = work_order_hash[product.id] + prod.split("_")[2].to_i
            else
              work_order_hash[product.id] = prod.split("_")[2].to_i
            end
          end
          #扣掉产品相应的库存
          product.update_attribute("storage", product.storage.to_f.round(2)-prod.split("_")[2].to_i)
          prod_ids_array << id
          prod_detail_hash = {:id => id, :name => product.name, :price => product.sale_price.to_f.round(2),
            :total_price => (product.sale_price.to_f.round(2) * prod.split("_")[2].to_i).round(2),
            :num => prod.split("_")[2].to_i, :type => 0, :valid_num => prod.split("_")[2].to_i}
          prods_and_cards << prod_detail_hash
          oder_total_price = oder_total_price + (product.sale_price.to_f.round(2) * prod.split("_")[2].to_i).round(2)
          actual_price = actual_price + (product.sale_price.to_f.round(2) * prod.split("_")[2].to_i).round(2)
        end
      when 1 #是服务
        #如果买的数量不为零则创建order_prod_relations(有可能为零)
        if prod.split("_")[2].to_i != 0
          product = Product.find_by_id(id)
          OrderProdRelation.create(:order_id => order.id, :item_id => id, :pro_num => prod.split("_")[2].to_i,
            :price => product.sale_price.to_f.round(2),
            :total_price => (product.sale_price.to_f.round(2) * prod.split("_")[2].to_i).round(2),
            :t_price => product.base_price.to_f.round(2), :prod_types => OrderProdRelation::PROD_TYPES[:SERVICE])
          if work_order_hash[product.id]
            work_order_hash[product.id] = work_order_hash[product.id] + prod.split("_")[2].to_i
          else
            work_order_hash[product.id] = prod.split("_")[2].to_i
          end
          prod_ids_array << id
          prod_detail_hash = {:id => id, :name => product.name, :price => product.sale_price.to_f.round(2),
            :total_price => (product.sale_price.to_f.round(2) * prod.split("_")[2].to_i).round(2),
            :num => prod.split("_")[2].to_i, :type => 1, :valid_num => prod.split("_")[2].to_i}
          prods_and_cards << prod_detail_hash
          oder_total_price = oder_total_price + (product.sale_price.to_f.round(2) * prod.split("_")[2].to_i).round(2)
          actual_price = actual_price + (product.sale_price.to_f.round(2) * prod.split("_")[2].to_i).round(2)
        end
      when 2 #打折卡
        dis_card = SvCard.find_by_id(id)
        OrderProdRelation.create(:order_id => order.id, :item_id => id, :pro_num => 1,
          :price => dis_card.price.to_f.round(2),
          :total_price => dis_card.price.to_f.round(2),
          :t_price => dis_card.price.to_f.round(2), :prod_types => OrderProdRelation::PROD_TYPES[:SV_CARD])
        CustomerCard.create(:customer_id => customer_id, :types => CustomerCard::TYPES[:DISCOUNT], 
          :status => CustomerCard::STATUS[:cancel], :card_id => dis_card.id, :discount => dis_card.discount.to_f.round(2),
          :order_id => order.id)
        prod_detail_hash = {:id => dis_card.id, :name => dis_card.name, :price => dis_card.price.to_f.round(2),
          :total_price => dis_card.price.to_f.round(2),
          :num => 1, :type => 2, :valid_num => 1}
        prods_and_cards << prod_detail_hash
        oder_total_price = oder_total_price + dis_card.price.to_f.round(2)
        actual_price = actual_price + dis_card.price.to_f.round(2)
      when 3 #套餐卡
        is_new = prod.split("_")[2].to_i
        if is_new == 1  #如果是新买的套餐卡
          con = []
          p_card = PackageCard.find_by_id(id)
          pprs = PcardProdRelation.find_by_sql(["select ppr.product_id, ppr.product_num, p.name from
              pcard_prod_relations ppr inner join products p on ppr.product_id=p.id
              where ppr.package_card_id=?", p_card.id])
          pprs.each do |ppr|
            str = "#{ppr.product_id}-#{ppr.name}-#{ppr.product_num.to_i}"   #1-xxx-22次,...
            con << str
            prod = Product.find_by_id(ppr.product_id) #如果套餐卡里包含产品 则要扣掉相应的库存
            if prod.is_service == false
              prod.update_attribute("storage", prod.storage.to_f.round(2)-ppr.product_num.to_i)
            end
          end if pprs.any?
          OrderProdRelation.create(:order_id => order.id, :item_id => id, :pro_num => 1,
            :price => p_card.price.to_f.round(2),
            :total_price => p_card.price.to_f.round(2),
            :t_price => p_card.price.to_f.round(2), :prod_types => OrderProdRelation::PROD_TYPES[:P_CARD])
          CustomerCard.create(:customer_id => customer_id, :types => CustomerCard::TYPES[:PACKAGE],
            :status => CustomerCard::STATUS[:cancel], :card_id => p_card.id, :package_content => con.join(","),
            :order_id => order.id)
          prod_detail_hash = {:id => p_card.id, :name => p_card.name, :price =>p_card.price.to_f.round(2),
            :total_price => p_card.price.to_f.round(2), :num => 1, :type => 2, :valid_num => 1}
          prods_and_cards << prod_detail_hash
          oder_total_price = oder_total_price + p_card.price.to_f.round(2)
          actual_price = actual_price +  p_card.price.to_f.round(2)
        elsif is_new == 0  #如果是用户已有的套餐卡下单
          pcard_arr = prod.split("_")
          pcard_prods = pcard_arr[3..-1]  #proId=num,proId=num,proId=num...
          pcard_prods.each do |pp|  
            pid = pp.split("=")[0].to_i
            pnum = pp.split("=")[1].to_i
            product = Product.find_by_id(pid)
            is_service = product.is_service
            OrderProdRelation.create(:order_id => order.id, :item_id => product.id, :pro_num => pnum,
              :price => product.sale_price.to_f.round(2),
              :total_price => (product.sale_price.to_f.round(2) * pnum).round(2),
              :t_price => product.base_price.to_f.round(2), :prod_types => OrderProdRelation::PROD_TYPES[:SERVICE],
              :customer_pcard_id => id)
            if is_service || product.is_added #如果用套餐卡下了服务或者需要施工的产品，则要加到排单
              if work_order_hash[product.id]
                work_order_hash[product.id] = work_order_hash[product.id] + pnum
              else
                work_order_hash[product.id] = pnum
              end
            end
            prod_ids_array << product.id
            by_pcard_buy_hash = {:customer_pcard_id => id, :product_id => product.id, :num => pnum}
            by_pcard_buy << by_pcard_buy_hash
            has_valid_hash = false
            prods_and_cards.each do |pac|
              if pac[:id] == product.id
                nums = pac[:num]
                pac[:num] = nums + pnum
                has_valid_hash = true
                break
              end
            end
            if has_valid_hash == false
              prod_detail_hash = {:id => product.id, :name => product.name, :price => product.sale_price.to_f.round(2),
                :total_price => (product.sale_price.to_f.round(2) * pnum).round(2),
                :num => pnum, :type => is_service ? 1 : 0, :valid_num => 0}
              prods_and_cards << prod_detail_hash
            end
            oder_total_price = oder_total_price + (product.sale_price.to_f.round(2) * pnum).round(2)
          end if pcard_prods.any?
        end
      when 4 #储值卡
        sv_card = SvCard.find_by_id(id)
        password = Digest::MD5.hexdigest(prod.split("_")[3])
        OrderProdRelation.create(:order_id => order.id, :item_id => id, :pro_num => 1,
          :price => sv_card.price.to_f.round(2),
          :total_price => sv_card.price.to_f.round(2),
          :t_price => sv_card.price.to_f.round(2), :prod_types => OrderProdRelation::PROD_TYPES[:SV_CARD])
        cc = CustomerCard.create(:customer_id => customer_id, :types => CustomerCard::TYPES[:STORED],
          :status => CustomerCard::STATUS[:cancel], :card_id => sv_card.id, :amt => sv_card.totle_price.to_f.round(2),
          :order_id => order.id, :password => password)
        SvcardUseRecord.create(:customer_card_id => cc.id, :types => SvcardUseRecord::TYPES[:IN],
          :use_price => 0, :left_price => sv_card.totle_price.to_f.round(2), :content => "购买储值卡#{sv_card.name}")
        prod_detail_hash = {:id => sv_card.id, :name => sv_card.name, :price => sv_card.price.to_f.round(2),
          :total_price => sv_card.price.to_f.round(2), :num => 1, :type => 2, :valid_num => 1}
        prods_and_cards << prod_detail_hash
        oder_total_price = oder_total_price + sv_card.price.to_f.round(2)
        actual_price = actual_price +  sv_card.price.to_f.round(2)
      end
    end if prods.any?
    work_order_hash.each do |k, v|
      product = Product.find_by_id(k)
      WorkOrder.create(:status => WorkOrder::STAT[:WAIT], :order_id => order.id,
        :current_day => Time.now.strftime("%Y%m%d").to_i, :store_id => store_id,
        :cost_time => product.cost_time.to_i * v, :service_id => product.id)
    end if work_order_hash.any?
    Station.arrange_work_orders store_id
    order.update_attribute("price", oder_total_price)
    if work_order_hash.blank? #如果该订单没有工单 说明只是单纯的买卡 应将订单状态置为等待付款
      order.update_attribute("status", Order::STATUS[:WAIT_PAYMENT])
    end
    return [ prod_ids_array, by_pcard_buy, prods_and_cards, order, actual_price]
  end

  #客户付款
  def self.pay_order order, is_please, pay_types, total_price, has_auth, pic=nil, is_billing=nil, is_free=nil, pay_type=nil, pwd=nil, csrid=nil
    status, msg = 1, ""
    if has_auth == 1  #如果有权限
      pay_type = pay_type.to_i
      if pay_type == 0 && total_price > 0 #现金
        OrderPayType.create(:order_id => order.id, :pay_type => OrderPayType::PAY_TYPES[:CASH],
          :price => total_price, :pay_status => OrderPayType::PAY_STATUS[:COMPLETE])
      elsif pay_type == 1 && total_price > 0 #储值卡 判断密码是否正确及金额是否足够
        card_flag = true
        csrid = csrid.to_i
        cus_scard = CustomerCard.find_by_id(csrid.to_i)
        my_log = Logger.new("#{Rails.root}/log/tst.log")
        my_log.info("pwd is #{pwd.class}")
        my_log.info("cus_scard is #{cus_scard}")
        if cus_scard.nil? || (cus_scard.password != Digest::MD5.hexdigest(pwd))
          status = 0
          msg = "储值卡不存在或密码错误!"
          card_flag= false
        elsif cus_scard.amt.to_f.round(2) < total_price
          status = 0
          msg = "储值卡余额不足!"
          card_flag = false
        end
        if card_flag  #储值卡扣钱
          cus_scard.update_attribute("amt", (cus_scard.amt.to_f.round(2) - total_price).round(2))
          SvcardUseRecord.create(:customer_card_id => cus_scard.id, :types => SvcardUseRecord::TYPES[:IN], :use_price => total_price,
            :left_price => (cus_scard.amt.to_f.round(2) - total_price).round(2), :content => "#{total_price}产品付费")
          OrderPayType.create(:order_id => order.id, :pay_type => OrderPayType::PAY_TYPES[:CASH],
            :price => total_price, :pay_status => OrderPayType::PAY_STATUS[:SV_CARD])
        end
      elsif  pay_type == 5 && total_price > 0 #免单
        OrderPayType.create(:order_id => order.id, :pay_type => OrderPayType::PAY_TYPES[:CASH],
          :price => total_price, :pay_status => OrderPayType::PAY_STATUS[:IS_FREE])
      end
      if status == 1
        make_order_pay_type pay_types, order
        #如果买了卡 要吧状态置为正常
        cus_cards = CustomerCard.where(["status=? and order_id=?", CustomerCard::STATUS[:cancel], order.id])
        cus_cards.each do |cc|
          cc.update_attribute("status", CustomerCard::STATUS[:normal])
        end
        order.update_attributes({:status => Order::STATUS[:BEEN_PAYMENT], :is_pleased => is_please, :is_billing => is_billing.nil? || is_billing==0 ? false : true,
            :is_free => is_free.nil? || is_free==0 ? false : true})
        if pic
          Customer.upload_sign_img pic, order
        end
      end
    else  #如果没权限
      make_order_pay_type pay_types, order
      order.update_attributes({:is_pleased => is_please, :is_billing => false, :is_free => false})
      if pic
        Customer.upload_sign_img pic, order
      end
    end
    return [status, msg]
  end

  private
  #生成订单的付款记录(通过活动，打折卡，套餐卡)
  def self.make_order_pay_type pay_types, order
    pay_arr = pay_types.split(",") if pay_types
    #1_47=255=20, 2_3_4=240.0=33_4=240.0=33, 3_4_4=7
    #活动－－1_活动的id_产品id＝优惠金额＝产品数量
    #打折卡－－2_打折卡与客户关联id_产品id=优惠金额＝产品数量
    #套餐卡－－3_套餐卡与客户关联id_产品id=产品数量
    pay_arr.each do |pa|
      type = pa.split("_")[0].to_i
      if type == 1  #活动优惠
        pa_arr = pa.split("_")
        sale_id = pa_arr[1].to_i
        items = pa_arr[2..-1] #47=255=20,...
        items.each do |item|
          pid = item.split("=")[0].to_i
          price = item.split("=")[1].to_f.round(2)
          num = item.split("=")[2].to_i
          OrderPayType.create(:order_id => order.id, :pay_type => OrderPayType::PAY_TYPES[:SALE], :price => price,
            :product_id => pid, :product_num => num, :pay_status => OrderPayType::PAY_STATUS[:COMPLETE])
        end if items.any?
        order.update_attribute("sale_id", sale_id)
      elsif type == 2   #打折卡
        pa_arr = pa.split("_")
        #customer_card_id = pa_arr[1].to_i
        items = pa_arr[2..-1]
        items.each do |item|
          if item && item.strip!=""
            pid = item.split("=")[0].to_i
            price = item.split("=")[1].to_f.round(2)
            num = item.split("=")[2].to_i
            OrderPayType.create(:order_id => order.id, :pay_type => OrderPayType::PAY_TYPES[:DISCOUNT_CARD],
              :price => price, :product_id => pid, :product_num => num,
              :pay_status => OrderPayType::PAY_STATUS[:COMPLETE])
          end
        end if items.any?
      elsif type == 3 #套餐卡
        pa_arr = pa.split("_")
        customer_card_id = pa_arr[1].to_i
        customer_card = CustomerCard.find_by_id(customer_card_id)
        card_contents = customer_card.package_content.split(",")  #[2-米其林轮胎-2,...]
        items = pa_arr[2..-1]
        items.each do |item|
          if item && item.strip!=""
            pid = item.split("=")[0].to_i
            num = item.split("=")[1].to_i
            product = Product.find_by_id(pid)
            price = product.sale_price.to_f.round(2) * num
            OrderPayType.create(:order_id => order.id, :pay_type => OrderPayType::PAY_TYPES[:PACJAGE_CARD],
              :price => price, :product_id => pid, :product_num => num,
              :pay_status => OrderPayType::PAY_STATUS[:COMPLETE])
            content_arr = []
            card_contents.each do |cc|
              cpid = cc.split("-")[0].to_i
              if cpid == pid
                left_num = cc.split("-")[2].to_i - num
                str = "#{cpid}-#{cc.split("-")[1]}-#{left_num}"
                content_arr << str
              else
                content_arr << cc
              end
            end if card_contents.any?
            card_contents = content_arr
          end
        end if items.any?
        card_flag = true
        card_contents.each do |cc|  #判断该套餐卡有没用光，用光则把卡的状态置为无效
          lnum = cc.split("-")[2].to_i
          if lnum > 0
            card_flag = false
            break
          end
        end
        customer_card.update_attributes({:package_content => card_contents.join(","),
            :status => card_flag==true ? CustomerCard::STATUS[:cancel] : CustomerCard::STATUS[:normal]})
      end
    end if pay_arr && pay_arr.any?
  end

  def self.upload_sign_img img, order  #上传客户付款时的签名图片
    root_path = "#{Rails.root}/public"
    dirs=["/signImgs","/#{order.code}"]
    dirs.each_with_index {|dir,index| Dir.mkdir root_path+dirs[0..index].join unless File.directory? root_path+dirs[0..index].join }
    img_name = img.original_filename
    filename="#{dirs.join}/sign_#{order.code}."+ img_name.split(".").reverse[0]
    File.open(root_path+filename, "wb")  {|f|  f.write(img.read) }
  end

end
