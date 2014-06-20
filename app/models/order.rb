#encoding: utf-8
class Order < ActiveRecord::Base
  has_many :order_prod_relations
  #  has_many :products, :through => :order_prod_relations
  has_many :order_pay_types
  has_many :work_orders
  belongs_to :car_num
  has_many :c_pcard_relations
  belongs_to :c_svc_relation
  belongs_to :customer
  belongs_to :sale
  has_many :revisit_order_relations
  has_many :o_pcard_relations
  has_many :complaints
  has_many :tech_orders

  IS_VISITED = {:YES => 1, :NO => 0} #1 已访问  0 未访问
  STATUS = {:NORMAL => 0, :SERVICING => 1, :WAIT_PAYMENT => 2, :BEEN_PAYMENT => 3, :FINISHED => 4, :DELETED => 5, :INNORMAL => 6,
    :RETURN => 7, :COMMIT => 8, :PCARD_PAY => 9}
  STATUS_NAME = {0 => "等待中", 1 => "服务中", 2 => "等待付款", 3 => "已经付款", 4 => "免单", 5 => "已删除" , 6 => "未分配工位",
    7 =>"退单", 8 => "已确认，未付款(后台付款)", 9 => "套餐卡下单,等待付款"}
  #0 正常未进行  1 服务中  2 等待付款  3 已经付款  4 已结束  5已删除  6未分配工位 7 退单
  CASH =[STATUS[:NORMAL],STATUS[:SERVICING],STATUS[:WAIT_PAYMENT],STATUS[:COMMIT]]
  OVER_CASH = [STATUS[:BEEN_PAYMENT],STATUS[:FINISHED],STATUS[:RETURN]]
  PRINT_CASH = [STATUS[:BEEN_PAYMENT],STATUS[:FINISHED]]
  IS_FREE = {:YES=>1,:NO=>0} # 1免单 0 不免单
  TYPES = {:SERVICE => 0, :PRODUCT => 1} #0 服务  1 产品
  FREE_TYPE = {:ORDER_FREE =>"免单",:PCARD =>"套餐卡使用"}
  #是否满意
  IS_PLEASED = {:BAD => 0, :SOSO => 1, :GOOD => 2, :VERY_GOOD => 3}  #0 不满意  1 一般  2 好  3 很好
  IS_PLEASED_NAME = {0 => "不满意", 1 => "一般", 2 => "好", 3 => "很好"}
  VALID_STATUS = [STATUS[:BEEN_PAYMENT], STATUS[:FINISHED]]
  O_RETURN = {:WASTE => 0, :REUSE => 1}  #  退单时 0 为报损 1 为回库
  DIRECT = {0=>"报损", 1=>"回库"}
  IS_RETURN = {:YES=>1,:NO=>0} #0  成功交易  1退货
  RETURN = {0 =>"成功交易" , 1 => "已退单"} 
  

  #根据需要回访的订单列出客户
  def self.get_order_customers(store_id, started_at, ended_at, car_num, is_vip, property, return_status, count, money)
    ids = []
    if count || money
      s_sql = ["select c.id, o.id oid,o.price from customers c inner join orders o on c.id=o.customer_id
        where c.store_id=? and o.status in (?)", store_id, [STATUS[:BEEN_PAYMENT], STATUS[:FINISHED]],]
      unless started_at.nil? || started_at==""
        s_sql[0] += " and o.created_at>=?"
        s_sql << started_at
      end
      unless ended_at.nil? || ended_at==""
        s_sql[0] += " and o.created_at<=?"
        s_sql << ended_at
      end
      if count && money.nil?
        s_sql[0] += " group by c.id having count(c.id)>=?"
        s_sql << count.to_i
        ids = self.find_by_sql(s_sql).map(&:id)
      elsif money && count.nil?
        s_sql[0] += " group by c.id having sum(o.price)>=?"
        s_sql << money.to_i
        ids = self.find_by_sql(s_sql).map(&:id)
      elsif money && count
        s_sql[0] += " group by c.id having count(c.id)>=? and sum(o.price)>=?"
        s_sql << count.to_i << money.to_i
        ids = self.find_by_sql(s_sql).map(&:id)
      end
    end
    sql = ["select cu.id cu_id, cu.name, cu.mobilephone, cu.property, o.code, o.id o_id, o.is_visited,
        o.price o_price, o.created_at o_time, cn.num, cm.name cmname, cb.name cbname from customers cu
        inner join orders o on o.customer_id = cu.id 
        left join car_nums cn on cn.id = o.car_num_id
        left join car_models cm on cn.car_model_id=cm.id
        left join car_brands cb on cm.car_brand_id=cb.id
        where cu.status=? and cu.store_id=? and o.store_id=? and o.status in (?)", Customer::STATUS[:NOMAL],
      store_id, store_id, [STATUS[:BEEN_PAYMENT], STATUS[:FINISHED]]]
    unless started_at.nil? || started_at==""
      sql[0] += " and o.created_at>=?"
      sql << started_at
    end
    unless ended_at.nil? || ended_at==""
      sql[0] += " and o.created_at<=?"
      sql << ended_at
    end
    if car_num
      sql[0] += " and cn.num like ?"
      sql << "%#{car_num.strip.gsub(/[%_]/){|x| '\\' + x}}%"
    end
    if is_vip && is_vip.to_i != -1
      sql[0] += " and cu.is_vip=?"
      sql << is_vip.to_i
    end
    if property && property.to_i != -1
      sql[0] += " and cu.property=?"
      sql << property.to_i
    end
    if return_status && return_status.to_i != -1
      sql[0] += " and o.is_visited=?"
      sql << return_status.to_i
    end
    if count || money
      if ids.any?
        sql[0] += " and cu.id in (?)"
        sql << ids.uniq
        order = self.find_by_sql(sql)
      else
        order = []
      end
    else
      order = self.find_by_sql(sql)
    end
    return order
  end

  #正在进行中的订单
  def self.working_orders store_id
    return Order.find_by_sql(["select o.id order_id,c.num car_nums,c.id car_id, o.status, wo.id wo_id, wo.status wo_status from orders o inner join car_nums c on c.id=o.car_num_id
      inner join customers cu on cu.id=o.customer_id left join work_orders wo on wo.order_id = o.id
      and wo.status not in (#{WorkOrder::STAT[:WAIT_PAY]},#{WorkOrder::STAT[:COMPLETE]},#{WorkOrder::STAT[:CANCELED]}, #{WorkOrder::STAT[:END]})
      where o.status in (#{STATUS[:NORMAL]}, #{STATUS[:SERVICING]}, #{STATUS[:WAIT_PAYMENT]}, #{STATUS[:BEEN_PAYMENT]}, #{STATUS[:FINISHED]})
      and DATE_FORMAT(o.created_at, '%Y%m%d')=DATE_FORMAT(NOW(), '%Y%m%d') and cu.status=? and o.store_id = ? order by o.status", Customer::STATUS[:NOMAL], store_id])
  end


  #订单详情
  def self.order_details order_id
    #顾客信息车型
    sql="select o.id,o.store_id,o.code,o.price,o.station_id,c.name,cn.num,c.mobilephone,c.property,cm.name car_model_name,cb.name car_brand_name,cn.buy_year,cn.vin_code,c.sex,c.group_name,cn.distance,o.cons_staff_id_1,o.cons_staff_id_2
    from orders o left JOIN car_nums cn on o.car_num_id = cn.id LEFT JOIN car_models cm on cn.car_model_id=cm.id
    LEFT JOIN car_brands cb on cb.id=cm.car_brand_id left JOIN customer_num_relations cnr on  cnr.car_num_id = cn.id
    left JOIN customers c on c.id=cnr.customer_id where o.id=?"
    order_details = Order.find_by_sql([sql,order_id]).first
    #订单详情
    order_pro = OrderProdRelation.find_by_sql("SELECT p.name,opr.price,opr.pro_num,opr.total_price from order_prod_relations opr
      INNER JOIN products p on opr.item_id = p.id where order_id = #{order_id} and prod_types=#{OrderProdRelation::PROD_TYPES[:SERVICE]}")
    #技师-施工技师
    staff_store = Staff.find_by_sql("SELECT id,name from staffs where type_of_w=#{Staff::S_COMPANY[:TECHNICIAN]} 
      and store_id=#{order_details.store_id} and status in (#{Staff::STATUS[:normal]},#{Staff::STATUS[:afl]},#{Staff::STATUS[:vacation]})")
    #已有工位的技师
    used_staffs = Staff.find_by_sql("SELECT id,name from staffs  where id in (#{order_details.cons_staff_id_1},#{order_details.cons_staff_id_2}) and store_id=#{order_details.store_id}")
    order_detail = order_details.attributes
    order_detail['order_pro'] = order_pro
    order_detail['staff_store'] = staff_store
    order_detail['used_staffs'] = used_staffs
    order_detail.delete('cons_staff_id_1')
    order_detail.delete('cons_staff_id_2')
    return order_detail
  end

  #根据车牌号码和手机号码查询
  def self.search_by_car_num store_id,car_num,types
    #0是查询，1是下单
    #查询出的车辆和用户
    sql = "select c.id customer_id,c.name,c.mobilephone,c.other_way email,c.birthday birth,c.sex,cn.buy_year year,
    cn.id car_num_id,cn.num,cm.name model_name,cn.distance,cb.name brand_name
    from customer_num_relations cnr
    inner join car_nums cn on cn.id=cnr.car_num_id
    inner join customers c on c.id=cnr.customer_id and c.status=#{Customer::STATUS[:NOMAL]} and cn.num='#{car_num}' or c.mobilephone='#{car_num}'
    left join car_models cm on cm.id=cn.car_model_id
    left join car_brands cb on cb.id=cm.car_brand_id "
    customers = CustomerNumRelation.find_by_sql sql
    customer_car_num_id = customers.map(&:car_num_id)
    customer_id = customers[0].nil? ? 0 : customers[0].customer_id
    #所有订单
    orders = Order.includes(:order_pay_types).find_by_sql(["select o.id,o.code,o.car_num_id,o.status,date_format(o.created_at,'%Y-%m-%d') as created,o.price,s.name from orders o
      INNER JOIN staffs s on s.id=o.front_staff_id where o.car_num_id in (?) and o.status!=#{STATUS[:DELETED]}
      and o.status != #{STATUS[:INNORMAL]} and o.store_id=#{store_id} order by o.created_at desc",customer_car_num_id])
    #    order_prod_relations = OrderProdRelation.includes(:product).where(:order_id => orders.map(&:id)).group_by { |pc| pc.order_id }
    order_prod_relations = OrderProdRelation.find_by_sql(["select p.name,opr.price,opr.pro_num,opr.total_price,opr.order_id from order_prod_relations opr
      INNER JOIN products p on opr.item_id = p.id where opr.prod_types=#{OrderProdRelation::PROD_TYPES[:SERVICE]}
      and opr.order_id in (?) ",orders.map(&:id)]).group_by{|pc| pc.order_id}

    order_prod_cards = OrderProdRelation.find_by_sql(["select cc.types,cc.card_id,opr.price,opr.pro_num,opr.total_price,opr.order_id
      from order_prod_relations opr INNER JOIN customer_cards cc on opr.item_id = cc.id
      where opr.prod_types=#{OrderProdRelation::PROD_TYPES[:CARD]} and opr.order_id in (?) ",orders.map(&:id)]).group_by{|pc| pc.order_id}
    orders_car_num = orders.group_by{|order| order.car_num_id }

    #套餐卡
    #该用户所购买的套餐卡
    customercards = CustomerCard.find_by_sql("select cc.id,cc.card_id,cc.types,cc.amt,cc.package_content,date_format(cc.ended_at,'%Y-%m-%d') as ended,pc.name from customer_cards cc
      INNER JOIN package_cards pc on cc.card_id = pc.id and cc.types = 3 and cc.status=1 and cc.ended_at>CURDATE()
      and cc.customer_id=#{customer_id}")
    customercard_ids = customercards.map(&:card_id)
    #用户套餐卡详细
    packagecards = PackageCard.find_by_sql(["select pc.id,p.id product_id,p.types,pc.name,p.name product_name,p.storage,ppr.product_num from package_cards pc
      INNER JOIN pcard_prod_relations ppr on pc.id=ppr.package_card_id
      INNER JOIN products p on p.id = ppr.product_id where pc.id in (?)",customercard_ids]).group_by{|packagecard| packagecard.id }
    package_cards = []
    customercards.each do |customercard|
      customer_card = {}
      customer_card['id'] = customercard.id
      customer_card['name'] = customercard.name
      customer_card['ended_at'] = customercard.ended
      customer_card['isnew'] = 0
      customer_card['types'] = 3
      products = []
      #套餐卡对应产品的剩余量
      if  packagecards[customercard.card_id]
        service_ma = Product.find_by_sql(["select min(p.storage/pmr.material_num) cishu,pmr.product_id from products p 
          INNER JOIN prod_mat_relations pmr on p.id=pmr.material_id where p.status = #{Product::STATUS[:NORMAL]} 
          and p.types=#{Product::TYPES[:MATERIAL]} and p.is_shelves=#{Product::IS_SHELVES[:YES]} and
          pmr.product_id in (?) GROUP BY pmr.product_id",packagecards[customercard.card_id].map(&:id)]).group_by{|serverse| serverse.product_id}
        
        packagecards[customercard.card_id].each do |product_package|
          product = {}
          if  product_package.types.to_i==Product::TYPES[:SERVICE]
            product['several_times'] = service_ma[product_package.product_id].nil? ? -1 : service_ma[product_package.product_id].first.cishu.to_i
          else
            product['several_times'] = product_package.storage.to_i
          end
          product['id'] = product_package.product_id
          product['name'] = product_package.product_name
          product['product_num'] = product_package.product_num
          customer_products = customercard.package_content.split(",") if customercard && customercard.package_content
          product['selected_num'] = 0
          product['unused_num'] = 0
          (customer_products || []).each do |customer_product|
            if customer_product.split("-")[0].to_i == product_package.product_id
              product['unused_num']= customer_product.split("-")[2].nil? ? 0 : customer_product.split("-")[2]
            end
          end
          products << product
        end 
      end
      customer_card['products'] = products
      package_cards << customer_card
    end
    #储值卡
    #该用户所购买的储值卡
    if types.to_i==0
      stored_cards = CustomerCard.find_by_sql("SELECT cc.id,sc.name,sc.totle_price,sc.description,sc.apply_content from sv_cards sc
        INNER JOIN customer_cards cc on sc.id=cc.card_id where cc.status=1 and cc.types=1 and cc.customer_id=#{customer_id}")
      storedcards_id =  stored_cards.map(&:id)
      stored_card_records = SvcardUseRecord.find_by_sql(["select sur.customer_card_id,sur.types,sur.use_price,sur.left_price,date_format(sur.created_at,'%Y-%m-%d') as created
        from svcard_use_records sur where sur.customer_card_id in (?) order by sur.created_at",storedcards_id]).group_by{|stored_card_record| stored_card_record.customer_card_id}
      stored_cards.each do |stored_card|
        stored_card['records'] = stored_card_records[stored_card.id].nil? ? [] : stored_card_records[stored_card.id]
        stored_card['last_time'] = stored_card_records[stored_card.id].nil? ? "" : stored_card_records[stored_card.id][0].created
        product_ids = stored_card.apply_content.nil? ? [] : stored_card.apply_content.split(",")
        products = Product.find_by_sql(["select p.id,p.name,p.sale_price from products p where p.id in (?) ",product_ids])
        stored_card['products'] = products
        stored_card['isnew'] = 0
        stored_card['types'] = 1
      end
      #打折卡
      discountcards = CustomerCard.find_by_sql("SELECT cc.id,sc.name,sc.totle_price,sc.discount,sc.apply_content,sc.description,sc.date_month,date_format(sc.ended_at,'%Y-%m-%d') as ended from sv_cards sc
        INNER JOIN customer_cards cc on sc.id=cc.card_id where cc.status=1 and cc.types=2 and cc.customer_id=#{customer_id}")
      discount_cards =[]
      discountcards.each do |discount_card|
        product_ids = discount_card.apply_content.nil? ? [] : discount_card.apply_content.split(",")
        products = Product.find_by_sql(["select p.id,p.name,p.sale_price from products p where p.id in (?) ",product_ids])
        discount_card['products'] = products
        discount_card['types'] = 2
        discount_card['isnew'] = 0
        discount_cards << discount_card
      end if discountcards
    else
      stored_cards = []
      discount_cards = []
    end
    
    info = []
    customers.each do |customer|
      #正在进行中和过往的订单
      customer['working_order']=[]
      customer['old_order']=[]
      orders_car_num[customer.car_num_id].each do |order_single|
        order_single['staff_name']=Staff.find_by_sql("select s.name from orders o INNER JOIN staffs s on s.id=o.cons_staff_id_1 or s.id=o.cons_staff_id_2 where o.id=#{order_single.id}").map(&:name).join(",")
        order_single['products']=[]
        car_order =[]
        #订单中的产品和服务
        order_prod_relations[order_single.id].each do |order_pro|
          #          product = order_pro.product
          car_order << {:name => order_pro.name, :price => order_pro.price,:pro_num=>order_pro.pro_num,:total_price => order_pro.total_price}
        end if order_prod_relations.present? && order_prod_relations[order_single.id].present?
        #订单中购买的卡类
        order_prod_cards[order_single.id].each do |order_card|
          if order_card.types == CustomerCard::TYPES[:PACKAGE]
            card_name = PackageCard.find_by_id order_card.card_id
          else
            card_name = SvCard.find_by_id order_card.card_id
          end
          car_order << {:name => card_name.name,:price => order_card.price,:pro_num=>order_card.pro_num,:total_price => order_card.total_price}
        end if order_prod_cards.present? && order_prod_cards[order_single.id].present?

        order_single['products'] = car_order
        #判断过往订单还是当前订单
        if order_single.status == STATUS[:BEEN_PAYMENT] or order_single.status == STATUS[:FINISHED]
          customer['old_order'] << order_single
        else
          customer['working_order'] << order_single
        end
      end if orders_car_num && orders_car_num[customer.car_num_id]

      info << customer
    end
    return [info,package_cards,discount_cards,stored_cards]
  end
  
  #下单

  # //type:0-产品  1-服务  2－打折卡  3－套餐卡  4-储值卡 //0_id_count_price //1_id_count_price //2_id_isNew_price //3_id_isNew_price(新的)
  # => //4_id_isNew_price_password //3_id_isNew_price_proId=num(老的)
  def self.pre_order store_id,car_num,mobilephone,buy_year,name,sex,property,group_name,distance,car_model_id,prods,user_id,price
    package_cards = [] #套餐卡
    customer_car = Hash.new #顾客车辆信息
    prod_goods = [] #产品
    prod_services = [] #服务
    discount_cards = [] #打折卡
    store_cards = [] # 储值卡
    status = 0
    Customer.transaction do
      customer = Customer.find_by_status_and_mobilephone(Customer::STATUS[:NOMAL], mobilephone)
      customer.update_attributes(:name => name.strip, :mobilephone => mobilephone,:property=>property,
        :group_name=>group_name,:sex => sex) if customer
      carNum = CarNum.find_by_num car_num
      customer,carNum = Customer.create_single_cus(customer, carNum, mobilephone, car_num,
        name.strip,buy_year,car_model_id,sex,store_id,distance)
      #用户和车辆信息
      customer_car[:c_id] = customer.id
      customer_car[:car_num] = car_num
      customer_car[:c_name] = customer.name
      customer_car[:phone] = mobilephone
      customer_car[:car_brand] = (carNum.car_model and carNum.car_model.car_brand) ? carNum.car_model.car_brand.name + "-" + carNum.car_model.name : ""
      customer_car[:car_num_id] = carNum.id
      customer_car['distance'] = distance
      customer_car['property'] = property
      customer_car['group_name'] = group_name
      arr = Product.order_products prods
      service_ids =  arr[1].collect{|service| service[1] }
      service = Product.where("id in (?) and status=?",service_ids,Product::STATUS[:NORMAL])
      order_cost_time = service.map(&:cost_time).inject{ |sum,ser| ser+sum }
      
      if service_ids.present?
        time_arr = Station.arrange_time store_id, service_ids, nil, nil
        customer_car[:station_id] = time_arr[0] || ""
        case time_arr[1]
        when 0
          status = 2 #没工位
        when 1
          status = 1  #有符合工位
        when 2
          status = 3 #多个工位
        when 3
          status = 4 #工位上暂无技师
        end
      end
      #有合适工位生成订单
      
      if status == 1 or status == 0
        order = Order.create({
            :code => ProductOrder.material_order_code(store_id.to_i),
            :car_num_id => carNum.try(:id),
            :status => Order::STATUS[:NORMAL],
            :price => price,
            :is_billing => false,
            :front_staff_id => user_id,
            :customer_id => customer.id,
            :store_id => store_id,
            :is_visited => Order::IS_VISITED[:NO],
            :types => arr[1].blank? ? 0 : Order::TYPES[:SERVICE]
          })
        customer_car["order_id"]= order.id
        customer_car["order_code"]= order.code
        if status == 1
          station_id = time_arr[0]
          work_order_status = time_arr[2]
          hash = Station.create_work_order(station_id, store_id,order, hash, work_order_status,order_cost_time.to_i)
          order.update_attributes hash
        end
        #建立关联关系
        #套餐卡
        
        (arr[3] || []).each do |prod|
          if prod[2].to_i == 1
            package_card = PackageCard.find_by_id prod[1].to_i
            customercard = CustomerCard.find_by_card_id_and_customer_id_and_types prod[1].to_i,customer.id,CustomerCard::TYPES[:PACKAGE]
            if package_card.date_types == PackageCard::TIME_SELCTED[:END_TIME]  #根据套餐卡的类型设置截止时间
              ended_at = (Time.now + customercard.days).to_date
            else
              ended_at = customercard.ended_at
            end
            if customercard
              opr_ncontent = PcardProdRelation.reset_content customercard.package_content,prod[1]
              customercard.update_attributes(:ended_at => ended_at,:package_content =>opr_ncontent)
            else
              CustomerCard.create(:customer_id => customer.id,:card_id=>customercard.id,:status=>SvCard::STATUS[:DELETED],
                :types=>CustomerCard::TYPES[:PACKAGE], :ended_at => ended_at,:package_content =>PcardProdRelation.set_content(prod[1]))
            end
            package_cards << package_card
          else
            #3_id_isNew_price_proId=num(老的)
            customercard = CustomerCard.find_by_id  prod[1].to_i
            prod_pack = customercard.package_content.split(",")
            content_cuc =[]
            prod_pack.each do |prop|
              pro_p = prop.split("-")
              if pro_p[0].to_i == prod[4].split("=")[0]
                numb = pro_p[2].to_i - prod[4].split("=")[1].to_i
              else
                numb = pro_p[2].to_i
              end
              content_cuc << pro_p[0]+ '-' + pro_p[1] + "-" + numb.to_s
            end
            OPcardRelation.create({:order_id => order.id, :customer_card_id => prod[1].to_i,
                :product_id =>prod[4].split("=")[0].to_i, :product_num =>prod[4].split("=")[1].to_i})
          end
        end
        opcardre = OPcardRelation.where("order_id=#{order.id}").group_by{|opcard|  opcard.product_id }
        #产品，服务，储值卡，套餐卡，打折卡
        customer_pcards =CustomerCard.where("customer_id=#{customer.id} and types=#{CustomerCard::TYPES[:PACKAGE]} and status=#{CustomerCard::STATUS[:normal]}")
        customer_discounts = CustomerCard.where("customer_id=#{customer.id} and types=#{CustomerCard::TYPES[:DISCOUNT]} and status=#{CustomerCard::STATUS[:normal]}")
        (arr[0] || []).each do |prod|
          goods = Product.find_by_id prod[1]
          prod_good = CustomerCard.product_has_cards customer_pcards,prod,opcardre,{},goods,customer_discounts
          prod_goods << prod_good
          OrderProdRelation.create(:order_id => order.id, :item_id => prod[1],:prod_types=>OrderProdRelation::PROD_TYPES[:SERVICE],
            :pro_num => prod[2], :price => goods.sale_price, :t_price => goods.t_price, :total_price => prod[3])
          goods.update_attributes(:storage => goods.storage-prod[2].to_i)
        end
        #服务
        (arr[1] || []).each do |prod|
          goods = Product.find_by_id prod[1]
          prod_good = CustomerCard.product_has_cards customer_pcards,prod,opcardre,{},goods,customer_discounts
          prod_services << prod_good
          OrderProdRelation.create(:order_id => order.id, :item_id => prod[1],:prod_types=>OrderProdRelation::PROD_TYPES[:SERVICE],
            :pro_num => prod[2], :price => goods.sale_price, :t_price => goods.t_price, :total_price => prod[3])
          goods.update_attributes(:storage => goods.storage-prod[2].to_i)
          materials = Product.find_by_sql(["SELECT p.id,pmr.product_id,pmr.material_num from products p INNER JOIN prod_mat_relations pmr on pmr.material_id = p.id
            INNER JOIN products p2 on p2.id=pmr.product_id where p2.is_service = #{Product::IS_SERVICE[:NO]} and pmr.product_id=#{prod[1]}"])
          materials.each do |m|
            mat = Product.find_by_id m.id
            mat.update_attributes(:storage => (mat.storage - m.material_num)) if mat
          end
        end
        #打折卡
        (arr[2] || []).each do |prod|
          card = SvCard.find_by_id prod[1]
          discount_cards << card
          customercard = CustomerCard.create(:customer_id => customer.id,:card_id=>card.id,:status=>SvCard::STATUS[:DELETED],
            :types=>CustomerCard::TYPES[:DISCOUNT],:discount=>card.discount,:package_content=>card.apply_content)
          OrderProdRelation.create(:order_id => order.id,:item_id => customercard.customer_id,:prod_types=>OrderProdRelation::PROD_TYPES[:CARD],
            :pro_num => 1,:price => card.price, :t_price => card.price, :total_price => prod[3])
        end

        #储值卡
        (arr[4] || []).each do |prod|
          store_card = SvCard.find_by_id prod[1]
          store_cards << store_card
          customercard = CustomerCard.where("customer_id=#{customer.id}").where("types=#{CustomerCard::TYPES[:STORED]}")
          .where("card_id=#{prod[1]}").first
          if customercard
            customercard.update_attributes(:amt=>store_card.totle_price + customercard.amt,:password => prod[4])
            SvcardUseRecord.create(:customer_card_id =>customercard.id,:types=>SvcardUseRecord::TYPES[:IN],:use_price=>store_card.totle_price,
              :left_price=>store_card.totle_price+customercard.amt,:content=>"充值#{store_card.name}")
          else
            customercard = CustomerCard.create(:customer_id => customer.id,:card_id=>store_card.id,:amt=>store_card.totle_price,
              :status=>SvCard::STATUS[:DELETED],:types=>CustomerCard::TYPES[:STORED],:password => prod[4],:package_content=>store_card.apply_content)
            SvcardUseRecord.create(:customer_card_id =>customercard.id,:types=>SvcardUseRecord::TYPES[:IN],:use_price=>store_card.totle_price,
              :left_price=>store_card.totle_price,:content=>"购买#{store_card.name}")
          end
        end
      end
    end
#    package_cards = [] #套餐卡
#    customer_car = Hash.new #顾客车辆信息
#    prod_goods = [] #产品
#    prod_services = [] #服务
#    discount_cards = [] #打折卡
#    store_cards = [] # 储值卡
    [status,customer_car,prod_goods,prod_services,discount_cards,package_cards,store_cards]
  end

  #获取产品相关的活动，打折卡，套餐卡
  def self.get_prod_sale_card prods
    #"prods"=>"0_311_1,0_310_1,3_10_1_310=1-311=1-" # 打着卡：2_id_price(优惠jine)
    arr = prods.split(",")
    prod_arr = []
    sale_arr = []
    svcard_arr = []
    pcard_arr = []
    arr.each do |p|
      if p.split("_")[0].to_i == 0
        #p  0_id_count
        prod_arr << p.split("_")
      elsif p.split("_")[0].to_i == 1
        #p 1_id_prod1=price1_prod2=price2_totalprice_realy_price
        sale_arr << p.split("_")
      elsif p.split("_")[0].to_i == 2
        #p 2_id
        svcard_arr << p.split("_")
      elsif p.split("_")[0].to_i == 3
        #p 3_id_has_p_card_prodId=prodId
        pcard_arr << p.split("_")
      end
    end
    [prod_arr,sale_arr,svcard_arr,pcard_arr]
  end

  #生成订单
  def self.make_record c_id,store_id,car_num_id,start,end_at,prods,price,station_id,user_id
    #"prods"=>"0_311_1,0_310_1,3_10_1_310=1-311=1-" # 产品／服务 ：0，活动：1， 打折卡：2， 套餐卡：3
    # prods"=>"0_311_1,0_310_1,3_10_1_310=1-311=1-
    arr = []
    status = 0
    order = nil
    Order.transaction do
      #begin
      arr = self.get_prod_sale_card prods
      #2_id_card_type_（is_new）_price 储值卡格式
      #[[["0", "311", "9"], ["0", "310", "2"]], [], [[2,1,0,0,20],...], [["3", "10", "0", "310=2-311=7-"], ["3", "11", "0"], ["3", "10", "1", "311=2-"]]]
      sale_id = arr[1].size > 0 ? arr[1][0][1] : ""  #活动

      order = Order.create({
          :code => ProductOrder.material_order_code(store_id.to_i),
          :car_num_id => car_num_id,
          :status => Order::STATUS[:INNORMAL],
          :price => price,
          :is_billing => false,
          :front_staff_id => user_id,
          :customer_id => c_id,
          :store_id => store_id,
          :is_visited => IS_VISITED[:NO]
        })
      if order
        hash = Hash.new
        x = 0
        cost_time = 0
        prod_ids = []
        is_has_service = false #用来记录是否有服务
        order_prod_relations = [] #用来记录订单中的所有的产品+物料
        product_prices = {}
        #存储sv_cards
        if arr[2].size > 0
          used_cards = arr[2].select{|ele| ele[4].to_f > 0} || []
          used_svcard_id = used_cards.flatten[1] #已经使用的打折卡的id
          #2_id_card_type_（is_new）_price 储值卡格式
          arr[2].select{|ele| ele[3].to_i == 1}.each do |uc|
            if uc[3]=="1" #新套餐卡
              sv_card = SvCard.find_by_id uc[1]
              if sv_card
                if sv_card.types== SvCard::FAVOR[:SAVE]  #储值卡
                  #                  sv_prod_relation = sv_card.svcard_prod_relations[0]
                  #                  if sv_prod_relation
                  customercard = CustomerCard.where("customer_id=#{c_id}").where("types=#{CustomerCard::TYPES[:STORED]}")
                  .where("card_id=#{sv_card.id}").where("store_id=#{store_id}").first
                  if customercard
                    customercard.update_attributes(:amt=>sv_card.totle_price + customercard.amt)
                    SvcardUseRecord.create(:customer_card_id =>customercard.id,:types=>SvcardUseRecord::TYPES[:IN],:use_price=>sv_card.totle_price,
                      :left_price=>sv_card.totle_price+customercard.amt,:content=>"充值#{sv_card.name}")
                  else
                    customercard = CustomerCard.create(:customer_id => c_id,:card_id=>sv_card.id,:amt=>sv_card.totle_price,:status=>SvCard::STATUS[:DELETED],:types=>CustomerCard::TYPES[:STORED])
                    SvcardUseRecord.create(:customer_card_id =>customercard.id,:types=>SvcardUseRecord::TYPES[:IN],:use_price=>sv_card.totle_price,
                      :left_price=>sv_card.totle_price,:content=>"购买#{sv_card.name}")
                  end
                  #                    total_price = sv_prod_relation.base_price.to_f+sv_prod_relation.more_price.to_f
                  #                    c_sv_relation = CSvcRelation.create!( :customer_id => c_id, :sv_card_id => uc[1], :order_id => order.id, :total_price => total_price,:left_price =>total_price, :status => CSvcRelation::STATUS[:invalid])
                  #                    SvcardUseRecord.create(:c_svc_relation_id =>c_sv_relation.id,:types=>SvcardUseRecord::TYPES[:IN],:use_price=>total_price,
                  #                      :left_price=>total_price,:content=>"购买#{sv_card.name}")
                else   #打折卡
                  customercard = CustomerCard.create(:customer_id => c_id,:card_id=>sv_card.id,:status=>SvCard::STATUS[:DELETED],:types=>CustomerCard::TYPES[:DISCOUNT],:discount=>sv_card.discount)
                  #                  CSvcRelation.create!(:customer_id => c_id, :sv_card_id => uc[1], :order_id => order.id, :total_price => sv_card.price, :status => CSvcRelation::STATUS[:invalid])
                end
                #储值卡和打折卡与order的关系
                OrderProdRelation.create(:order_id => order.id, :item_id => customercard.id,
                  :pro_num => 1, :price => sv_card.totle_price, :total_price => sv_card.totle_price,:prod_types=>OrderProdRelation::PROD_TYPES[:CARD])
              end
            end
          end
        end
        #创建订单的相关产品 OrdeProdRelation
        (arr[0] || []).each do |prod|
          product = Product.find_by_id_and_store_id_and_status prod[1],store_id,Product::STATUS[:NORMAL]
          if product
            order_p_r = OrderProdRelation.create(:order_id => order.id, :item_id => prod[1],
              :pro_num => prod[2], :price => product.sale_price, :t_price => product.t_price, :total_price => prod[3].to_f,:prod_types=>OrderProdRelation::PROD_TYPES[:SERVICE])
            order_prod_relations << order_p_r
            if product.is_service
              x += 1
              cost_time += product.cost_time.to_i * prod[2].to_i
              prod_ids << product.id
              is_has_service = true
            end
            product_prices[product.id] = product.sale_price
          end
        end
        hash[:types] = x > 0 ? TYPES[:SERVICE] : TYPES[:PRODUCT]
        if order_prod_relations  #如果是产品,则减掉对应库存
          order_prod_h = order_prod_relations.group_by { |o_p| o_p.item_id }
          products = Product.find_by_sql(["select * from products p where p.is_service=#{Product::IS_SERVICE[:NO]} and p.id in (?)",order_prod_h.keys])
          products.each do |pro|
            pro.update_attributes(:storage => (pro.storage - order_prod_h[pro.product_id][0].pro_num)) if order_prod_h[pro.product_id]
          end
          materials = Product.find_by_sql(["SELECT p.id,pmr.product_id,pmr.material_num from products p INNER JOIN prod_mat_relations pmr on pmr.material_id = p.id
            INNER JOIN products p2 on p2.id=pmr.product_id where p2.is_service = #{Product::IS_SERVICE[:NO]} and pmr.product_id in (?)", order_prod_h.keys])
          materials.each do |m|
            mat = Product.find_by_id m.id
            mat.update_attributes(:storage => (mat.storage - order_prod_h[m.product_id][0].pro_num)) if order_prod_h[m.product_id]
          end unless materials.blank?
        end
        #订单相关的活动
        if sale_id != "" && Sale.find_by_id_and_store_id_and_status(sale_id,store_id,Sale::STATUS[:RELEASE])
          if arr[1][0][2]
            p_prcent = arr[1][0][-1].to_f/arr[1][0][-2].to_f

            (2..(arr[1][0].length - 3)).each do |i|
              p_info = arr[1][0][i].split("=")
              OrderPayType.create(:order_id => order.id, :pay_type => OrderPayType::PAY_TYPES[:SALE],
                :product_id => p_info[0].to_i, :price => p_info[1].to_f * p_prcent)
            end
          end
          hash[:sale_id] = sale_id
        end

        #订单相关的套餐卡
        prod_hash = {}  #用来记录套餐卡中总共使用了多少
        if arr[3].any?
          #[["3", "10", "0", "310=2-311=7-"], ["3", "11", "0"], ["3", "10", "1", "311=2-"]]
          p_c_ids = {} #统计有多少套餐卡中消费
          pc_ids = {} #套餐卡同种套餐卡数量
          arr[3].collect do |a_pc|
            pc_ids[a_pc[1].to_i] = pc_ids[a_pc[1].to_i].nil? ? 1 : (pc_ids[a_pc[1].to_i] + 1)
            pro_infos = p_c_ids[a_pc[1].to_i].nil? ? {} : p_c_ids[a_pc[1].to_i]
            pinfos = a_pc[3].split("-") if a_pc[3]
            pinfos.each do |p_f|
              id = p_f.split("=")[0].to_i
              num = p_f.split("=")[1].to_i
              pro_infos[id] = pro_infos[id].nil? ? num : (pro_infos[id].to_i + num)
              prod_hash[id] = prod_hash[id].nil? ? num : (prod_hash[id].to_i + num)
            end if pinfos and pinfos.any?
            p_c_ids[a_pc[1].to_i] = pro_infos #{10=>{310=>2, 311=>9}, 11=>{}}
          end
          #获取套餐卡
          #arr[3]=[["3", "10", "0", "310=2-311=7-"], ["3", "11", "0"], ["3", "10", "1", "311=2-"]]
          # 3表示是套餐卡，10是套餐卡id，0表示新旧套餐卡，其后表示product或者service的id，最后是用户套餐卡关系id customer_card的id
          p_cards = PackageCard.find(:all, :conditions => ["status = ? and store_id = ? and id in (?)",
              PackageCard::STAT[:NORMAL], store_id, p_c_ids.keys])
          if p_cards.any?
            p_cards_hash = p_cards.group_by { |p_c| p_c.id }
            arr[3].collect do |a_pc|
              prod_nums = a_pc[3].split("-") if a_pc[3]
              if a_pc[2].to_i == 0 #has_p_card是0，表示是新买的套餐卡
                p_card_id = a_pc[1].to_i
                if p_cards_hash[p_card_id][0].date_types == PackageCard::TIME_SELCTED[:END_TIME]  #根据套餐卡的类型设置截止时间
                  ended_at = (Time.now + (p_cards_hash[p_card_id][0].date_month).days).to_date
                else
                  ended_at = p_cards_hash[p_card_id][0].ended_at
                end
                cpr = CustomerCard.where("customer_id=#{c_id}").where("types=#{CustomerCard::TYPES[:PACKAGE]}")
                .where("card_id=#{p_card_id}").where("store_id=#{store_id}").first
                if cpr
                  opr_ncontent = PcardProdRelation.reset_content cpr.content,p_card_id
                  cpr.update_attributes(:ended_at => ended_at,:content =>opr_ncontent)
                else
                  cpr = CustomerCard.create(:customer_id => c_id,:card_id=>p_card_id,:status=>SvCard::STATUS[:DELETED],
                    :types=>CustomerCard::TYPES[:PACKAGE], :ended_at => ended_at,:content =>PcardProdRelation.set_content(p_card_id))
                end
                #创建订单与购买套餐卡的关系
                #储值卡和打折卡与order的关系
                OrderProdRelation.create(:order_id => order.id, :item_id => cpr.id,:pro_num => 1,
                  :price => p_cards_hash[p_card_id][0].price,:total_price => p_cards_hash[p_card_id][0].price,:prod_types=>OrderProdRelation::PROD_TYPES[:CARD])
                #                cpr = CPcardRelation.create(:customer_id => c_id, :package_card_id =>p_card_id,
                #                  :status => CPcardRelation::STATUS[:INVALID], :ended_at => ended_at,
                #                  :content => CPcardRelation.set_content(p_card_id), :order_id => order.id,
                #                  :price => p_cards_hash[p_card_id][0].price)
                if a_pc[3] # 如果使用套餐卡，把使用的次数保存
                  (prod_nums||[]).each do |pn|
                    prod_id = pn.split("=")[0]
                    p_num = pn.split("=")[1]
                    OPcardRelation.create({:order_id => order.id, :customer_card_id => cpr.id,
                        :product_id =>prod_id, :product_num => p_num})
                  end
                end
              else #已经买过套餐卡
                ## 如果使用套餐卡，把使用的次数保存
                cpr = CustomerCard.find_by_id a_pc[4]
                (prod_nums||[]).each do |pn|
                  prod_id = pn.split("=")[0]
                  p_num = pn.split("=")[1]
                  OPcardRelation.create({:order_id => order.id, :customer_card_id => a_pc[4],
                      :product_id =>prod_id, :product_num => p_num})
                end
              end
              if cpr
                prod_nums_hash = {}
                (prod_nums||[]).map{|pn| pn.split("=")}.map{|pn| prod_nums_hash[pn[0]] = pn[1]}
                cpr_content = cpr.content.split(",")
                content = []
                (cpr_content ||[]).each do |pnn|
                  prod_name_num = pnn.split("-")
                  prod_id = prod_name_num[0]
                  if prod_nums_hash[prod_id]
                    content << "#{prod_id.to_i}-#{prod_name_num[1]}-#{prod_name_num[2].to_i - prod_nums_hash[prod_id].to_i}"
                  else
                    content << pnn
                  end
                end
                cpr.update_attribute(:content, content.join(","))
              end
            end
            #创建套餐卡优惠的价格
            unless prod_hash.empty?
              prod_hash.each { |k, v|
                pcard_dis_price = product_prices[k].to_f * v
                OrderPayType.create(:order_id => order.id, :pay_type => OrderPayType::PAY_TYPES[:PACJAGE_CARD],
                  :product_id => k, :price => pcard_dis_price, :product_num => v)
              }
            end
          end
        end

        #订单相关的打折卡(使用的)
        unless used_svcard_id.blank?
          sv_card = SvCard.find_by_id(used_svcard_id)
          if sv_card
            discount_card = CustomerCard.find_by_customer_id_and_card_id_and_types c_id,used_svcard_id,CustomerCard::TYPES[:DISCOUNT]
            discount_card = CustomerCard.create(:customer_id => c_id,:card_id=>used_svcard_id,:types=>CustomerCard::TYPES[:DISCOUNT],:discount=>sv_card.discount,:status=>SvCard::STATUS[:normal]) if discount_card.nil?
            #            c_sv_relation = CSvcRelation.find_by_customer_id_and_sv_card_id c_id,used_svcard_id
            #            c_sv_relation = CSvcRelation.create(:customer_id => c_id, :sv_card_id => used_svcard_id) if c_sv_relation.nil?
            apply_products_id = sv_card.apply_content.split(",") if sv_card.apply_content
            order_prod_relations.each do |o_p_r|
              if apply_products_id.include?(o_p_r.product_id)
                OrderPayType.create(:order_id => order.id, :pay_type => OrderPayType::PAY_TYPES[:DISCOUNT_CARD],
                  :product_id => o_p_r.product_id, :price => (o_p_r.total_price.to_f) *((10 - sv_card.discount).to_f/10))
              end
            end if arr[2][0][2] and order_prod_relations.any?
            #打折卡只能对产品打折
            #
            #
            #            csvc_relations = CSvcRelation.where(:order_id => order.id)
            #            csvc_relations.each do |csvc_relation|
            #              sv_card_new = SvCard.find_by_id(csvc_relation.sv_card_id)
            #              sv_price =  sv_card_new.sale_price
            #              OrderPayType.create(:order_id => order.id, :pay_type => OrderPayType::PAY_TYPES[:DISCOUNT_CARD],
            #                :price => (sv_price.to_f) *((10 - sv_card.discount).to_f/10))
            #            end
            #            c_pcard_relations = CPcardRelation.where(:order_id => order.id)
            #            c_pcard_relations.each do |cpr|
            #              OrderPayType.create(:order_id => order.id, :pay_type => OrderPayType::PAY_TYPES[:DISCOUNT_CARD],
            #                :price => (cpr.price.to_f) *((10 - sv_card.discount).to_f/10))
            #            end
            hash[:discount_card] = discount_card.id if discount_card
          end
        end

        if is_has_service
          #创建工位订单
          #station = Station.find_by_id_and_status station_id, Station::STAT[:NORMAL]
          #unless station
          arrange_time = Station.arrange_time(store_id,prod_ids,order,nil)
          if arrange_time[2] > 0
            new_station_id = arrange_time[2]
            start_at = arrange_time[0]
            station = Station.find_by_id_and_status new_station_id, Station::STAT[:NORMAL]
          end
          #end
          if station
            woTime = WkOrTime.find_by_station_id_and_current_day new_station_id, Time.now.strftime("%Y%m%d").to_i
            if woTime
              t =  Time.zone.parse(woTime.current_times) + Constant::W_MIN.minutes
              start  = t > Time.zone.parse(start_at) ? t : Time.zone.parse(start_at)
              end_at = start + cost_time.minutes
              woTime.update_attributes(:current_times => end_at.strftime("%Y%m%d%H%M").to_i, :wait_num => woTime.wait_num.to_i + 1)
            else
              start = Time.zone.parse(start_at)
              end_at = Time.zone.parse(start_at) + cost_time.minutes
              WkOrTime.create(:current_times => end_at.strftime("%Y%m%d%H%M"), :current_day => Time.now.strftime("%Y%m%d").to_i,
                :station_id => station.id, :worked_num => 1)
            end
            work_order = WorkOrder.create({
                :order_id => order.id,
                :current_day => Time.now.strftime("%Y%m%d"),
                :station_id => station.id,
                :store_id => store_id,
                :status => (woTime.nil? ? WorkOrder::STAT[:SERVICING] : WorkOrder::STAT[:WAIT]),
                :started_at => start,
                :ended_at => end_at
              })
            hash[:status] = (work_order.status == WorkOrder::STAT[:SERVICING]) ? STATUS[:SERVICING] : STATUS[:NORMAL]
            hash[:station_id] = new_station_id
            station_staffs = StationStaffRelation.find_all_by_station_id_and_current_day station.id, Time.now.strftime("%Y%m%d").to_i
            hash[:cons_staff_id_1] = station_staffs[0].staff_id if station_staffs.size > 0
            hash[:cons_staff_id_2] = station_staffs[1].staff_id if station_staffs.size > 1
            hash[:started_at] = start
            hash[:ended_at] = end_at
            order.update_attributes hash
            status = 1
          else
            status = 3
          end
        else
          hash[:station_id] = ""
          hash[:cons_staff_id_1] = ""
          hash[:cons_staff_id_2] = ""
          hash[:started_at] = start
          hash[:ended_at] = end_at
          hash[:status] = STATUS[:WAIT_PAYMENT]
          order.update_attributes hash
          status = 1
        end
      end
      #rescue
      #status = 2
      #end
    end
    arr[0] = status
    arr[1] = order
    arr
  end

  
  #返回订单的相关信息
  def get_info
    hash = Hash.new
    hash[:id] = self.id
    hash[:code] = self.code
    car_num = self.car_num
    hash[:car_num] = car_num.num
    hash[:username] = self.customer.name
    hash[:start] = self.started_at.strftime("%Y-%m-%d %H:%M") if self.started_at
    hash[:end] = self.ended_at.strftime("%Y-%m-%d %H:%M") if self.ended_at
    hash[:total] = self.price
    content = ""
    realy_price = 0
    sale = nil
    unless self.sale_id.blank?
      h = {}
      sale = self.sale
      h[:name] = sale.name
      self.order_pay_types.each do |o_p_t|
        if o_p_t.pay_type == OrderPayType::PAY_TYPES[:SALE]
          h[:price] = h[:price].nil? ? o_p_t.price.to_f : (h[:price] + o_p_t.price.to_f)
        end
      end
      h[:type] = 1
      hash[:sale] = h
    end
    #产品或者服务
    hash[:products] = self.order_prod_relations.collect{|r|
      if r.prod_types.to_i== OrderProdRelation::PROD_TYPES[:SERVICE]
        h = Hash.new
        h[:id] = r.item_id
        product_names = Product.find_by_id h[:id]
        h[:name] = product_names.name
        h[:price] = r.price
        h[:num] = r.pro_num.to_i
        h[:type] = 0
        content += h[:name] + ","
        h
      end
    }
    hash[:content] = content.chomp(",")

    #套餐卡
    hash[:package_card] = self.order_prod_relations.collect{|r|
      if r.prod_types.to_i== OrderProdRelation::PROD_TYPES[:CARD]
        buy_package_card = CustomerCard.find_by_sql("SELECT pc.id,pc.name from customer_cards cc INNER JOIN package_cards pc on cc.card_id=pc.id
          where cc.types=#{CustomerCard::TYPES[:PACKAGE]} and cc.id=#{r.item_id}")
        if buy_package_card
          h = Hash.new
          h[:id] = r.item_id
          h[:name] = buy_package_card[0].nil? ? 0 : buy_package_card[0].name
          h[:price] = r.price
          h[:num] = r.pro_num.to_i
          h[:type] = 3
        end
      end
    }
    #打折卡
    hash[:sv_card_discount] = self.order_prod_relations.collect{|r|
      if r.prod_types.to_i== OrderProdRelation::PROD_TYPES[:CARD]
        buy_svcard_discount = CustomerCard.find_by_sql("SELECT sc.id,sc.name from customer_cards cc INNER JOIN sv_cards sc on cc.card_id=sc.id
          where cc.types=#{CustomerCard::TYPES[:DISCOUNT]} and cc.id=#{r.item_id}")
        if buy_svcard_discount
          h = Hash.new
          h[:id] = r.item_id
          h[:name] = buy_svcard_discount[0].nil? ? 0 : buy_svcard_discount[0].name
          h[:price] = r.price
          h[:num] = r.pro_num.to_i
          h[:type] = 2
        end
      end
    }

    #储值卡
    hash[:sv_card_store] = self.order_prod_relations.collect{|r|
      if r.prod_types.to_i== OrderProdRelation::PROD_TYPES[:CARD]
        buy_svcard_store = CustomerCard.find_by_sql("SELECT sc.id,sc.name from customer_cards cc INNER JOIN sv_cards sc on cc.card_id=sc.id
          where cc.types=#{CustomerCard::TYPES[:STORED]} and cc.id=#{r.item_id}")
        if buy_svcard_store
          h = Hash.new
          h[:id] = r.item_id
          h[:name] = buy_svcard_store[0].nil? ? 0 : buy_svcard_store[0].name
          h[:price] = r.price
          h[:num] = r.pro_num.to_i
          h[:type] = 1
        end
      end
    }

    #订单确认后显示页面上面关于打折卡信息

    #    hash[:c_svc_relation] = []
    #    csvc_relations = CSvcRelation.where(:order_id => self.id).each{|csvc| csvc[:is_new] = 1}
    #    unless self.c_svc_relation_id.blank?
    #      csvc_relation = CSvcRelation.find_by_id(self.c_svc_relation_id)
    #      csvc_relation[:is_new] = 0 if csvc_relation
    #      csvc_relations << csvc_relation
    #    end

    #    sav_price = 0
    #    self.order_pay_types.each do |o_p_t|
    #      if o_p_t.pay_type == OrderPayType::PAY_TYPES[:DISCOUNT_CARD]
    #        sav_price += o_p_t.price
    #      end
    #    end
    #    csvc_relations.each do |csvc|
    #      h = {}
    #      sv_card = SvCard.find_by_id(csvc.sv_card_id)
    #      price =  sv_card.sale_price
    #      h[:name] = sv_card.name
    #      h[:price] = ((csvc.id == self.c_svc_relation_id) ? sav_price : price)
    #      h[:discount] = sv_card.types==SvCard::FAVOR[:DISCOUNT] ? sv_card.discount : 0  #0表示是储值卡
    #      h[:type] = 2
    #      h[:card_type] = sv_card.types #0 打折卡 1 储值卡
    #      h[:is_new] = csvc.is_new
    #      hash[:c_svc_relation] << h
    #    end unless csvc_relations.blank?
    #    hash[:c_pcard_relation] = []
    #    customer_pcards = CPcardRelation.find_by_sql(["select pc.* from c_pcard_relations cpr
    #        inner join package_cards pc on pc.id = cpr.package_card_id
    #        where cpr.order_id = ?#", self.id])
    #    customer_pcards.each do |cp|
    #      hash[:c_pcard_relation] << {:name => cp.name, :price => cp.price, :num => 1, :type => 3}
    #      content += cp.name + ","
    #      realy_price += cp.price
    #    end unless customer_pcards.blank?
    #    self.o_pcard_relations.group_by{|opr| opr.c_pcard_relation_id}.each do |c_pcard_relarion_id, oprs|
    #      cpr = CPcardRelation.find_by_id c_pcard_relarion_id
    #      name = cpr.package_card.name
    #      price = oprs.map{|opr| [opr.product.sale_price.to_f, opr.product_num]}.inject(0){|sum, pn| sum += pn[0].to_f*pn[1].to_f}.to_f
    #      hash[:c_pcard_relation] << {:name => name, :price => -price, :num => 1, :type => 3}
    #    end
    hash
  end


  #支付订单根据选择的支付方式
  def self.pay order_id, store_id, please, pay_type, billing, code, is_free
    order = Order.find_by_id_and_store_id order_id,store_id
    status = 0
    if order
      Order.transaction do
        begin
          hash = Hash.new
          hash[:is_billing] = billing.to_i == 0 ? false : true
          hash[:is_pleased] = please.to_i
          if is_free.to_i == 0
            hash[:status] = STATUS[:BEEN_PAYMENT]
            hash[:is_free] = false
          else
            hash[:status] = STATUS[:FINISHED]
            hash[:is_free] = true
            hash[:price] = 0
          end
          p 1111111111111111111
          #如果有套餐卡，则更新状态
          customer_cards = CustomerCard.find_by_sql("SELECT cc.* from order_prod_relations opr INNER JOIN customer_cards cc on opr.item_id=cc.id
            where opr.order_id=#{order.id} and opr.prod_types=#{OrderProdRelation::PROD_TYPES[:CARD]}").group_by{|customer_card| customer_card.types }
          #套餐卡改变状态
          customer_cards[CustomerCard::TYPES[:PACKAGE]].each do |custcard|
            custcard.update_attributes(:status => CustomerCard::STATUS[:normal])
          end unless customer_cards[CustomerCard::TYPES[:PACKAGE]].blank?
          

          #          c_pcard_relations = CPcardRelation.find_all_by_order_id(order.id)
          #          c_pcard_relations.each do |cpr|
          #            cpr.update_attribute(:status, CPcardRelation::STATUS[:NORMAL])
          #          end unless c_pcard_relations.blank?

          #储值卡更改状态
          customer_cards[CustomerCard::TYPES[:STORED]].each { |customer_card| customer_card.update_attributes(:status =>CustomerCard::STATUS[:normal]) } if customer_cards[CustomerCard::TYPES[:STORED]]
          #打折卡更改状态
          customer_cards[CustomerCard::TYPES[:DISCOUNT]].each { |customer_card| customer_card.update_attributes(:status =>CustomerCard::STATUS[:normal]) } if customer_cards[CustomerCard::TYPES[:DISCOUNT]]
          #如果有买储值卡，则更新状态
          #          csvc_relations = CSvcRelation.where(:order_id => order.id)
          #          csvc_relations.each{|csvc_relation| csvc_relation.update_attributes({:status => CSvcRelation::STATUS[:valid], :is_billing => hash[:is_billing]})}
          if customer_cards
            c_s_r = Customer.find_by_id order.customer_id
            c_s_r.update_attributes(:is_vip => Customer::IS_VIP[:VIP])
          end
          #          if c_pcard_relations.present? || csvc_relations.present?
          #            c_s_r = CustomerStoreRelation.find_by_store_id_and_customer_id(order.store_id, order.customer_id)
          #            c_s_r.update_attributes(:is_vip => Customer::IS_VIP[:VIP])
          #          end
          #如果是选择储值卡支付
          if pay_type.to_i == OrderPayType::PAY_TYPES[:SV_CARD] && code
            #c_svc_relation = CSvcRelation.find_by_id order.c_svc_relation_id
            #if c_svc_relation && c_svc_relation.left_price.to_f >= order.price.to_f
            content = "订单号为：#{order.code},消费：#{order.price}."
            #sv_use_record = SvcardUseRecord.create(:c_svc_relation_id => c_svc_relation.id,
            #                                       :types => SvcardUseRecord::TYPES[:OUT],
            #                                       :use_price => order.price,
            #                                       :content => content,
            #                                       :left_price => (c_svc_relation.left_price - order.price)
            #)
            #c_svc_relation.update_attribute(:left_price,sv_use_record.left_price) if sv_use_record
            svc_return_record = SvcReturnRecord.find_all_by_store_id(store_id,:order => "created_at desc", :limit => 1)
            if svc_return_record.size > 0

              total = svc_return_record[0].total_price - order.price
              SvcReturnRecord.create(:store_id => store_id, :price => order.price, :types => SvcReturnRecord::TYPES[:OUT],
                :content => content, :target_id => order.id, :total_price => total)
            else
              SvcReturnRecord.create(:store_id => store_id, :price => order.price, :types => SvcReturnRecord::TYPES[:OUT],
                :content => content, :target_id => order.id, :total_price => -order.price)
            end
            order.update_attributes hash
            OrderPayType.create(:order_id => order_id, :pay_type => pay_type.to_i, :price => order.price)
            status = 1
          else
            order.update_attributes hash
            OrderPayType.create(:order_id => order_id, :pay_type => pay_type.to_i, :price => order.price)
            status = 1
          end
          wo = WorkOrder.find_by_order_id(order.id)
          wo.update_attribute(:status, WorkOrder::STAT[:COMPLETE]) if wo and wo.status==WorkOrder::STAT[:WAIT_PAY]
          #生成积分的记录
          #          c_customer = CustomerStoreRelation.find_by_store_id_and_customer_id(order.store_id,order.customer_id)
          if c_s_r && c_s_r.is_vip
            points = Order.joins("inner join order_prod_relations opr on opr.order_id=orders.id inner join products on products.id=opr.item_id and
              opr.prod_types=#{OrderProdRelation::PROD_TYPES[:SERVICE]}#").select("products.prod_point*opr.pro_num point").where("orders.id=#{order.id}")
            .inject(0){|sum,porder|(porder.point.nil? ? 0 :porder.point)+sum}+
              PackageCard.where("id in (?)",customer_cards[CustomerCard::TYPES[:PACKAGE]].nil? ? 0 : customer_cards[CustomerCard::TYPES[:PACKAGE]].map(&:package_card_id))
            .map(&:prod_point).compact.inject(0){|sum,pcard|sum+pcard}
            Point.create(:customer_id=>c_s_r.id,:target_id=>order.id,:target_content=>"购买产品/服务/套餐卡获得积分",:point_num=>points,:types=>Point::TYPES[:INCOME])
            c_s_r.update_attributes(:total_point=>points+(c_s_r.total_point.nil? ? 0 : c_s_r.total_point))
          end
          #生成出库记录
          order_mat_infos = Order.find_by_sql(["SELECT o.id o_id, o.front_staff_id, p.id p_id, opr.pro_num material_num, m.id m_id, m.sale_price m_price
            FROM orders o inner join order_prod_relations opr on o.id = opr.order_id inner join products p on
            p.id = opr.item_id inner join prod_mat_relations pmr on pmr.product_id = p.id inner join products m
            on m.id = pmr.material_id where p.is_service = #{Product::IS_SERVICE[:YES]} and o.status in (?) and o.id = ?", [STATUS[:BEEN_PAYMENT], STATUS[:FINISHED]], order.id])
          order_mat_infos.each do |omi|
            #            MatOutOrder.create({:material_id => omi.m_id, :staff_id => omi.front_staff_id, :material_num => omi.material_num,
            #                :price => omi.m_price, :types => MatOutOrder::TYPES_VALUE[:sale], :store_id => store_id})
            ProdOutOrder.create(:product_id=>omi.m_id,:staff_id=>omi.front_staff_id,:product_num=>omi.material_num,
              :price=>omi.m_price,:types=>ProdOutOrder::TYPES_VALUE[:sale],:store_id => store_id)
          end
        rescue
          status = 2
        end
      end
    else
      status = 2
    end
    [status]
  end

  # 取消订单后，退回使用套餐卡数量
  def return_order_pacard_num
    oprs = OPcardRelation.find_all_by_order_id(self.id)
    oprs.each do |opr|
      cpr = CustomerCard.find_by_id(opr.customer_card_id)
      pns = cpr.content.split(",").map{|pn| pn.split("-")} if cpr
      pns.each do |pn|
        pn[2] = pn[2].to_i + opr.product_num if pn[0].to_i == opr.product_id
      end if pns
      cpr.update_attribute(:content,pns.map{|pn| pn.join("-")}.join(",")) if cpr
    end unless oprs.blank?
  end
  
  # 取消订单后，退回产品或者服务相关物料数量
  def return_order_materials
    order_products = OrderProdRelation.where("order_id=#{self.id}").where("prod_types=#{OrderProdRelation::PROD_TYPES[:SERVICE]}").group_by{|opr| opr.id}
    p 5555555555,order_products.keys
    #    order_products = self.order_prod_relations.group_by { |opr| opr.product_id }
    if order_products  #如果是产品,则减掉要加回来
      products = Product.find_by_sql(["select * from products p where p.is_service=#{Product::IS_SERVICE[:NO]} and p.id in (?)",order_products.keys])
      products.each do |pro|
        pro.update_attributes(:storage => (pro.storage + order_products[pro.product_id][0].pro_num)) if order_products[pro.product_id]
      end
      materials = Product.find_by_sql(["SELECT p.id,pmr.product_id,pmr.material_num from products p INNER JOIN prod_mat_relations pmr on pmr.material_id = p.id
        INNER JOIN products p2 on p2.id=pmr.product_id where p2.is_service = #{Product::IS_SERVICE[:NO]} and pmr.product_id in (?)", order_products.keys])
      materials.each do |m|
        mat = Product.find_by_id m.id
        mat.update_attributes(:storage => (mat.storage - order_products[m.product_id][0].pro_num)) if order_products[m.product_id]
      end unless materials.blank?
      #      materials = Material.find_by_sql(["select m.id, pmr.product_id from materials m inner join prod_mat_relations pmr
      #                on pmr.material_id = m.id inner join products p on p.id = pmr.product_id
      #                where p.is_service = #{Product::PROD_TYPES[:PRODUCT]} and pmr.product_id in (?)#", order_products.keys])
      #      materials.each do |m|
      #        mat = Material.find_by_id m.id
      #        mat.update_attributes(:storage => (mat.storage + order_products[m.product_id][0].pro_num)) if mat and order_products[m.product_id]
      #      end unless materials.blank?
    end
    #    #归还跟套餐卡相关的物料
    #    cpcard_relations = self.c_pcard_relations
    #    if cpcard_relations.present?
    #      package_card_ids = cpcard_relations.map(&:package_card_id)
    #      pcmrs = PcardMaterialRelation.where(:package_card_id => package_card_ids)
    #      pcmrs.each do |pcmr|
    #        material = pcmr.material
    #        material.update_attribute(:storage, material.storage + pcmr.material_num) if material
    #      end if pcmrs.present?
    #    end
  end

  def rearrange_station  #如果存在work_order,取消订单后设置work_order以及wk_or_times里面的部分数值
    work_order = self.work_orders[0]

    unless work_order.blank?
      if work_order.status == WorkOrder::STAT[:SERVICING]
        work_order.update_attribute(:status, WorkOrder::STAT[:CANCELED])
        work_order.arrange_station
      else
        work_order.update_attribute(:status, WorkOrder::STAT[:CANCELED])
      end
    end
  end
end
