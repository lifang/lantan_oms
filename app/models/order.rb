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
  
  def self.one_order_info(order_id)
    return Order.find_by_sql(["select o.*, c.name front_s_name, c1.name cons_s_name1,c3.name return_name,
      c2.name cons_s_name2, o.front_staff_id, o.cons_staff_id_1, o.cons_staff_id_2, o.customer_id,o.status
      from orders o left join staffs c on c.id = o.front_staff_id left join staffs c1 on c1.id = o.cons_staff_id_1
      left join staffs c2 on c2.id = o.cons_staff_id_2 left join staffs c3 on c3.id = o.return_staff_id where o.id = ?", order_id]).first
  end

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


  #  #施工中的订单
  #  def self.working_orders store_id
  #    stations =Station.where("store_id=#{store_id} and status !=#{Station::STAT[:DELETED]}")
  #    sql = "select c.num,w.station_id,w.status,w.order_id from work_orders w inner join orders o on w.order_id=o.id inner join car_nums c on c.id=o.car_num_id
  # where w.current_day= '#{Time.now.strftime("%Y%m%d")}' and w.status in (#{WorkOrder::STAT[:SERVICING]},#{WorkOrder::STAT[:WAIT_PAY]},#{WorkOrder::STAT[:WAIT]}) and w.store_id=#{store_id}#"
  #    work_orders = WorkOrder.find_by_sql(sql).group_by {|work_order| work_order.status}
  #    of_waiting = work_orders[WorkOrder::STAT[:WAIT]]
  #    orders_id = work_orders[WorkOrder::STAT[:SERVICING]].nil? ? [] : work_orders[WorkOrder::STAT[:SERVICING]].map(&:order_id)
  #    of_working = work_orders[WorkOrder::STAT[:SERVICING]].group_by { |working| working.station_id } if work_orders[WorkOrder::STAT[:SERVICING]]
  #    of_completed = work_orders[WorkOrder::STAT[:WAIT_PAY]]
  #    products = Product.find_by_sql("select id,name from products where status=#{Product::STATUS[:NORMAL]} and is_service = #{Product::PROD_TYPES[:SERVICE]} and store_id = #{store_id}")
  #    order_pro_rel = Product.joins(" p INNER JOIN order_prod_relations opr on p.id=opr.product_id").
  #      joins("inner join work_orders wo on wo.order_id=opr.order_id").select("p.id,p.name,opr.order_id,wo.station_id").
  #      where(["opr.order_id in (?)",orders_id]).group_by{|order_pro| order_pro.station_id}
  #    stations_order = []
  #    stations.each do |station|
  #      station_obj = station.attributes
  #      station_obj['of_working'] = of_working.present? && of_working[station.id].present? ?  of_working[station.id] : []
  #      station_obj['service'] = order_pro_rel.present? && order_pro_rel[station.id].present? ? order_pro_rel[station.id] : []
  #      stations_order << station_obj
  #    end if stations
  #    return [of_waiting,stations_order, of_completed,products]
  #  end

  #正在进行中的订单
  def self.working_orders store_id
    return Order.find_by_sql(["select o.id, c.num, o.status, wo.id wo_id, wo.status wo_status from orders o inner join car_nums c on c.id=o.car_num_id
      inner join customers cu on cu.id=o.customer_id left join work_orders wo on wo.order_id = o.id
and wo.status not in (#{WorkOrder::STAT[:WAIT_PAY]},#{WorkOrder::STAT[:COMPLETE]},#{WorkOrder::STAT[:CANCELED]}, #{WorkOrder::STAT[:END]})
      where o.status in (#{STATUS[:NORMAL]}, #{STATUS[:SERVICING]}, #{STATUS[:WAIT_PAYMENT]}, #{STATUS[:BEEN_PAYMENT]}, #{STATUS[:FINISHED]})
      and DATE_FORMAT(o.created_at, '%Y%m%d')=DATE_FORMAT(NOW(), '%Y%m%d') and cu.status=? and o.store_id = ? order by o.status", Customer::STATUS[:NOMAL], store_id])
  end


  #订单详情
  def self.order_details order_id
    #顾客信息车型
    sql="select o.id,o.store_id,o.code,o.price,c.name,cn.num,c.mobilephone,cm.name car_model_name,cb.name car_brand_name,cn.buy_year,c.sex,c.group_name,cn.distance,o.cons_staff_id_1,o.cons_staff_id_2
from orders o left JOIN car_nums cn on o.car_num_id = cn.id LEFT JOIN car_models cm on cn.car_model_id=cm.id
LEFT JOIN car_brands cb on cb.id=cm.car_brand_id left JOIN customer_num_relations cnr on  cnr.car_num_id = cn.id
left JOIN customers c on c.id=cnr.customer_id where o.id=?"
    order_details = Order.find_by_sql([sql,order_id]).first
    #订单详情
    order_pro = OrderProdRelation.find_by_sql("SELECT p.name,opr.price,opr.pro_num,opr.total_price from order_prod_relations opr
INNER JOIN products p on opr.product_id = p.id where order_id = #{order_id}")
    #技师-施工技师
    staff_store = Staff.find_by_sql("SELECT id,name from staffs where type_of_w=#{Staff::S_COMPANY[:TECHNICIAN]} and store_id=#{order_details.store_id}")
    return [order_details,order_pro,staff_store]
  end

  #根据车牌号码和手机号码查询
  def self.search_by_car_num store_id,car_num, car_id
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
    customer_id = customers[0].customer_id
    #所有订单
    orders = Order.includes(:order_pay_types).find_by_sql(["select o.id,o.code,o.car_num_id,o.status,o.created_at,o.price,s.name from orders o
          INNER JOIN staffs s on s.id=o.front_staff_id where o.car_num_id in (?) and o.status!=#{STATUS[:DELETED]}
          and o.status != #{STATUS[:INNORMAL]} and o.store_id=#{store_id} order by o.created_at desc",customer_car_num_id])
    order_prod_relations = OrderProdRelation.includes(:product).where(:order_id => orders.map(&:id)).group_by { |pc| pc.order_id }
    orders_car_num = orders.group_by{|order| order.car_num_id }

    #套餐卡
    #该用户所购买的套餐卡
    customercards = CustomerCard.find_by_sql("select cc.id,cc.card_id,cc.types,cc.amt,cc.package_content,cc.ended_at,pc.name from customer_cards cc
INNER JOIN package_cards pc on cc.card_id = pc.id and cc.types = 3 and cc.status=1 and cc.ended_at>CURDATE()
and cc.customer_id=#{customer_id}")
    customercard_ids = customercards.map(&:card_id)
    #用户套餐卡详细
    packagecards = PackageCard.find_by_sql(["select pc.id,p.id product_id,pc.name,p.name product_name,ppr.product_num from package_cards pc
INNER JOIN pcard_prod_relations ppr on pc.id=ppr.package_card_id
INNER JOIN products p on p.id = ppr.product_id where pc.id in (?)",customercard_ids]).group_by{|packagecard| packagecard.id }
    package_cards = []
    customercards.each do |customercard|
      customer_card = {}
      customer_card['id'] = customercard.id
      customer_card['name'] = customercard.name
      customer_card['ended_at'] = customercard.ended_at
      products = []
      packagecards[customercard.card_id].each do |product_package|
        product = {}
        product['id'] = product_package.product_id
        product['name'] = product_package.product_name
        product['product_num'] = product_package.product_num
        customer_products = customercard.package_content.split(",") if customercard && customercard.package_content
        product['unused_num'] = 0
        (customer_products || []).each do |customer_product|
          if customer_product.split("-")[0].to_i == product_package.product_id
            product['unused_num']= customer_product.split("-")[2].nil? ? 0 : customer_product.split("-")[2]
          end
        end
        products << product
      end
      customer_card['products'] = products
      package_cards << customer_card
    end
    #储值卡
    #该用户所购买的储值卡
    sql='select cc.id,sc.name,sc.totle_price,sc.created_at from customer_cards cc
INNER JOIN sv_cards sc on cc.card_id = sc.id where cc.types = 1 and cc.status=1  and cc.ended_at>CURDATE()'
    customercards = CustomerCard.find_by_sql("select cc.id,cc.card_id,cc.types,cc.amt,cc.package_content,cc.ended_at,pc.name from customer_cards cc
INNER JOIN package_cards pc on cc.card_id = pc.id and cc.types = 3 and cc.status=1 and cc.ended_at>CURDATE()
and cc.customer_id=#{customer_id}")
    #打折卡
    discountcards = CustomerCard.find_by_sql("SELECT cc.id,sc.name,sc.totle_price,sc.discount,sc.apply_content,sc.description from sv_cards sc
INNER JOIN customer_cards cc on sc.id=cc.card_id where cc.status=1 and cc.types=1 and cc.customer_id=#{customer_id}")
    discount_cards =[]
    discountcards.each do |discount_card|
      product_ids = discount_card.apply_content.nil? ? [] : discount_card.apply_content.split(",")
      products = Product.find_by_sql(["select p.id,p.name,p.sale_price from products p where p.id in (?) ",product_ids])
      discount_card['products'] = products
      discount_cards << discount_card
    end

    info = []
    customers.each do |customer|
      #正在进行中和过往的订单
      customer['working_order']=[]
      customer['old_order']=[]
      orders_car_num[customer.car_num_id].each do |order_single|
        order_single['products']=[]
        car_order =[]
        order_prod_relations[order_single.id].each do |order_pro|
          product = order_pro.product
          car_order << {:name => product.name, :price => order_pro.price,:pro_num=>order_pro.pro_num,:total_price => order_pro.total_price} if product
        end if order_prod_relations.present? && order_prod_relations[order_single.id].present?
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
    return [info,package_cards,discount_cards]
  end
  #  def self.search_by_car_num store_id,car_num, car_id
  #    customer = nil
  #    working_orders = []
  #    old_orders = []
  #    #or c.mobilephone='#{car_num}'
  #    sql = "select c.id customer_id,c.name,c.mobilephone,c.other_way email,c.birthday birth,c.sex,cn.buy_year year,
  #      cn.id car_num_id,cn.num,cm.name model_name,cb.name brand_name
  #      from customer_num_relations cnr
  #      inner join car_nums cn on cn.id=cnr.car_num_id
  #      inner join customers c on c.id=cnr.customer_id and c.status=#{Customer::STATUS[:NOMAL]} and cn.num='#{car_num}'
  #      left join car_models cm on cm.id=cn.car_model_id
  #      left join car_brands cb on cb.id=cm.car_brand_id #"
  #    customer = CustomerNumRelation.find_by_sql sql
  #    p customer
  #    if customer && customer.size > 0
  #      customer = customer[0]
  #      customer.birth = customer.birth.strftime("%Y-%m-%d")  if customer.birth
  #      orders = Order.includes(:order_pay_types).find_by_sql("select * from orders o where o.car_num_id=#{customer.car_num_id}
  #       and o.status!=#{STATUS[:DELETED]} and o.status != #{STATUS[:INNORMAL]} and o.store_id=#{store_id} order by o.created_at desc#")
  #      #订单中购买的套餐卡
  #      package_cards = CustomerCard.find_by_sql(["select cc.order_id, pc.name, pc.price from customer_cards cc
  #          inner join package_cards pc
  #           on pc.id = cc.card_id and cc.types=2 where cc.order_id in (?)#", orders]).group_by { |pc| pc.order_id }
  #      csvc_relations = CustomerCard.includes(:sv_card).where(:order_id => orders.map(&:id)).where(:types=>3).group_by { |pc| pc.order_id }
  #      order_prod_relations = OrderProdRelation.includes(:product).where(:order_id => orders.map(&:id)).group_by { |pc| pc.order_id }
  #      order_pay_types = OrderPayType.where(:order_id => orders.map(&:id)).group_by{|opt| opt.order_id}
  #      staffs = Order.find_by_sql(["SELECT o.id, s.name FROM orders o inner join staffs s on o.front_staff_id = s.id where o.id in (?) and s.store_id = ?", orders, store_id]).group_by{|o| o.id}
  #      (orders || []).each do |order|
  #        order_hash = order
  #        #每个订单中的产品
  #        order_hash[:products] = []
  #        order_prod_relations[order.id].each do |opr|
  #          product = opr.product
  #          order_hash[:products] << {:name => product.name, :price => opr.price.to_f * opr.pro_num.to_i} if product
  #        end if order_prod_relations.present? && order_prod_relations[order.id].present?
  #
  ##        #每个订单中的储值卡、打折卡
  ##        csvc_relations[order.id].each do |csvc_r|
  ##          sv_card = csvc_r.sv_card
  ##          sv_price =  sv_card.sale_price
  ##          order_hash[:products] << {:name => sv_card.try(:name), :price => sv_price}
  ##        end if csvc_relations.present? && csvc_relations[order.id].present?
  #
  #        #每个订单中的套餐卡
  #        package_cards[order.id].each do |o_pc|
  #          order_hash[:products] << {:name => o_pc.name, :price => o_pc.price}
  #        end if package_cards.present? && package_cards[order.id].present?
  #
  #        #订单对应的付款方式
  #        order_hash[:pay_type] = order_pay_types[order.id].collect{|type|
  #          OrderPayType::PAY_TYPES_NAME[type.pay_type]
  #        }.join(",") unless order_pay_types[order.id].nil?
  #
  #        front_staff = staffs[order.id][0]
  #        order_hash[:staff] = front_staff.name if front_staff
  #
  #        if order.status == STATUS[:BEEN_PAYMENT] or order.status == STATUS[:FINISHED]
  #          old_orders << order_hash  #过往订单
  #        else
  #          if (car_id && car_id.to_i == order.id) || car_id.nil?
  #            working_orders << order_hash  #进行中的订单
  #          end
  #        end
  #      end
  ##      working_orders = working_orders.first if working_orders.size > 0
  #    end
  #    [customer,working_orders,old_orders]
  #  end



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
          :code => MaterialOrder.material_order_code(store_id.to_i),
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
                  sv_prod_relation = sv_card.svcard_prod_relations[0]
                  if sv_prod_relation
                    total_price = sv_prod_relation.base_price.to_f+sv_prod_relation.more_price.to_f
                    c_sv_relation = CSvcRelation.create!( :customer_id => c_id, :sv_card_id => uc[1], :order_id => order.id, :total_price => total_price,:left_price =>total_price, :status => CSvcRelation::STATUS[:invalid])
                    SvcardUseRecord.create(:c_svc_relation_id =>c_sv_relation.id,:types=>SvcardUseRecord::TYPES[:IN],:use_price=>total_price,
                      :left_price=>total_price,:content=>"购买#{sv_card.name}")

                  end
                else   #打折卡
                  CSvcRelation.create!(:customer_id => c_id, :sv_card_id => uc[1], :order_id => order.id, :total_price => sv_card.price, :status => CSvcRelation::STATUS[:invalid])
                end
              end
            end
          end

        end
        #创建订单的相关产品 OrdeProdRelation
        (arr[0] || []).each do |prod|
          product = Product.find_by_id_and_store_id_and_status prod[1],store_id,Product::IS_VALIDATE[:YES]
          if product
            order_p_r = OrderProdRelation.create(:order_id => order.id, :product_id => prod[1],
              :pro_num => prod[2], :price => product.sale_price, :t_price => product.t_price, :total_price => prod[3].to_f)
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
          order_prod_h = order_prod_relations.group_by { |o_p| o_p.product_id }
          materials = Material.find_by_sql(["select m.*, pmr.product_id from materials m inner join prod_mat_relations pmr
                on pmr.material_id = m.id inner join products p on p.id = pmr.product_id
                where p.is_service = #{Product::PROD_TYPES[:PRODUCT]} and pmr.product_id in (?)", order_prod_h.keys])
          materials.each do |m|
            m.update_attributes(:storage => (m.storage - order_prod_h[m.product_id][0].pro_num)) if order_prod_h[m.product_id]
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
          # 3表示是套餐卡，10是套餐卡id，0表示新旧套餐卡，其后表示product或者service的id，最后是用户套餐卡关系id CPcardRelation的id
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
                cpr = CPcardRelation.create(:customer_id => c_id, :package_card_id =>p_card_id,
                  :status => CPcardRelation::STATUS[:INVALID], :ended_at => ended_at,
                  :content => CPcardRelation.set_content(p_card_id), :order_id => order.id,
                  :price => p_cards_hash[p_card_id][0].price)
                if a_pc[3] # 如果使用套餐卡，把使用的次数保存
                  (prod_nums||[]).each do |pn|
                    prod_id = pn.split("=")[0]
                    p_num = pn.split("=")[1]
                    OPcardRelation.create({:order_id => order.id, :c_pcard_relation_id => cpr.id,
                        :product_id =>prod_id, :product_num => p_num})
                  end
                end
              else #已经买过套餐卡
                ## 如果使用套餐卡，把使用的次数保存
                cpr = CPcardRelation.find_by_id a_pc[4]
                (prod_nums||[]).each do |pn|
                  prod_id = pn.split("=")[0]
                  p_num = pn.split("=")[1]
                  OPcardRelation.create({:order_id => order.id, :c_pcard_relation_id => a_pc[4],
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
            c_sv_relation = CSvcRelation.find_by_customer_id_and_sv_card_id c_id,used_svcard_id
            c_sv_relation = CSvcRelation.create(:customer_id => c_id, :sv_card_id => used_svcard_id) if c_sv_relation.nil?
            order_prod_relations.each do |o_p_r|
              OrderPayType.create(:order_id => order.id, :pay_type => OrderPayType::PAY_TYPES[:DISCOUNT_CARD],
                :product_id => o_p_r.product_id, :price => (o_p_r.total_price.to_f) *((10 - sv_card.discount).to_f/10))
            end if arr[2][0][2] and order_prod_relations.any?
            csvc_relations = CSvcRelation.where(:order_id => order.id)
            csvc_relations.each do |csvc_relation|
              sv_card_new = SvCard.find_by_id(csvc_relation.sv_card_id)
              sv_price =  sv_card_new.sale_price
              OrderPayType.create(:order_id => order.id, :pay_type => OrderPayType::PAY_TYPES[:DISCOUNT_CARD],
                :price => (sv_price.to_f) *((10 - sv_card.discount).to_f/10))
            end
            c_pcard_relations = CPcardRelation.where(:order_id => order.id)
            c_pcard_relations.each do |cpr|
              OrderPayType.create(:order_id => order.id, :pay_type => OrderPayType::PAY_TYPES[:DISCOUNT_CARD],
                :price => (cpr.price.to_f) *((10 - sv_card.discount).to_f/10))
            end
            hash[:c_svc_relation_id] = c_sv_relation.id if c_sv_relation
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
end
