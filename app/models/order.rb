#encoding: utf-8
class Order < ActiveRecord::Base
  has_many :order_prod_relations
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
    :RETURN => 7, :COMMIT => 8, :PCARD_PAY => 9, :UNCONFIRMED => 10}
  STATUS_NAME = {0 => "等待中", 1 => "服务中", 2 => "等待付款", 3 => "已经付款", 4 => "免单", 5 => "已删除" , 6 => "未分配工位",
    7 =>"退单", 8 => "已确认，未付款(后台付款)", 9 => "套餐卡下单,等待付款", 10 => "未确认"}
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
    return Order.find_by_sql(["select o.*, cn.id cnid, cn.num cnum, cn.buy_year buy_year, cn.vin_code, cn.distance, cu.id cuid, cu.name cname,
      cu.mobilephone cphone, cu.sex csex, cu.property  property, cu.group_name, cm.name model_name, cb.name brand_name
      from orders o inner join car_nums cn on cn.id=o.car_num_id
      inner join customers cu on cu.id=o.customer_id
      left join car_models cm on cn.car_model_id=cm.id
      left join car_brands cb on cm.car_brand_id=cb.id
      where o.status in (#{STATUS[:NORMAL]}, #{STATUS[:SERVICING]}, #{STATUS[:WAIT_PAYMENT]}, #{STATUS[:BEEN_PAYMENT]})
      and DATE_FORMAT(o.created_at, '%Y%m%d')=DATE_FORMAT(NOW(), '%Y%m%d') and cu.status=? and o.store_id =?", Customer::STATUS[:NOMAL], store_id])
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

  #根据车牌号码或手机号码查询
  def self.search_by_car_num store_id,car_num,is_car_num,search_type #search_type 是搜索页面还是开单页面
    status = 1
    msg = ""
    hash = {}
    customer_arr = []
    package_arr = []
    begin
      if is_car_num == 0  #根据车牌查询
        car_and_cus = CarNum.find_by_sql(["select cn.id cnid, cn.num cnum, cn.buy_year, cn.distance, cn.vin_code,
          cm.name model_name, cb.name brand_name, c.id cus_id, c.other_way email, c.birthday, c.mobilephone, c.name cus_name,
          c.sex, c.property, c.group_name from car_nums cn inner join customer_num_relations cnr on cn.id=cnr.car_num_id
          inner join customers c on cnr.customer_id=c.id
          left join car_models cm on cn.car_model_id=cm.id
          left join car_brands cb on cm.car_brand_id=cb.id
          where cn.num=? and c.store_id=? and c.status=?", car_num, store_id, Customer::STATUS[:NOMAL]]).first
        if car_and_cus
          cus_hash = {:brand_name => car_and_cus.brand_name, :car_num_id => car_and_cus.cnid,
            :customer_id => car_and_cus.cus_id,
            :distance => car_and_cus.distance, :email => car_and_cus.email, :mobilephone => car_and_cus.mobilephone,
            :model_name => car_and_cus.model_name, :name => car_and_cus.cus_name, :num => car_and_cus.cnum,
            :sex => car_and_cus.sex ? 0 : 1, :year => car_and_cus.buy_year, :property => car_and_cus.property,
            :group_name => car_and_cus.group_name, :vin => car_and_cus.vin_code}
          if search_type == 0
            cus_hash[:working_orders] = Customer.get_customer_working_orders(car_and_cus.cus_id, car_and_cus.cnid)
          else
            package_arr = Customer.get_customer_package_cards car_and_cus.cus_id
            cus_hash[:working_orders] = []
          end
          customer_arr << cus_hash  #[{:brand_name=>...}]
        end
        if search_type == 0
          hash[:customer] = customer_arr    #{:customer => [{:brand_name=>...}],}
        else
          hash[:cus_card] = {:package_cards => package_arr}
          hash[:cus] = {:customer => customer_arr}
        end
      elsif is_car_num == 1  #根据手机号查询
        car_and_cuses = CarNum.find_by_sql(["select cn.id cnid, cn.num cnum, cn.buy_year, cn.distance, cn.vin_code,
          cm.name model_name, cm.id model_id, cb.name brand_name, cb.id brand_id, c.id cus_id, c.other_way email, c.birthday, c.mobilephone, c.name cus_name,
          c.sex, c.property, c.group_name from car_nums cn inner join customer_num_relations cnr on cn.id=cnr.car_num_id
          inner join customers c on cnr.customer_id=c.id
          inner join car_models cm on cn.car_model_id=cm.id
          inner join car_brands cb on cm.car_brand_id=cb.id
          where c.mobilephone=? and c.store_id=? and c.status=?", car_num, store_id, Customer::STATUS[:NOMAL]])
        car_and_cuses.each do |car_and_cus|
          cus_hash = {:brand_name => car_and_cus.brand_name, :brand_id => car_and_cus.brand_id,
            :car_num_id => car_and_cus.cnid, :customer_id => car_and_cus.cus_id,
            :distance => car_and_cus.distance, :email => car_and_cus.email, :mobilephone => car_and_cus.mobilephone,
            :model_name => car_and_cus.model_name, :model_id => car_and_cus.model_id,
            :name => car_and_cus.cus_name, :num => car_and_cus.cnum,
            :sex => car_and_cus.sex ? 0 : 1, :year => car_and_cus.buy_year, :property => car_and_cus.property,
            :group_name => car_and_cus.group_name, :vin => car_and_cus.vin_code}
          if search_type == 0
            cus_hash[:working_orders] = Customer.get_customer_working_orders(car_and_cus.cus_id, car_and_cus.cnid)
          else
            cus_hash[:working_orders] = []
          end
          customer_arr << cus_hash  #[{:brand_name=>...}]
        end if car_and_cuses.any?
        if search_type == 0
          hash[:customer] = customer_arr    #{:customer => [{:brand_name=>...}],}
        else
          package_arr = Customer.get_customer_package_cards(car_and_cuses[0].cus_id) if car_and_cuses.any?
          hash[:cus_card] = {:package_cards => package_arr}
          hash[:cus] = {:customer => customer_arr}
        end
      end
    rescue
      status = 0
      msg = "数据错误!"
    end
    return [status, msg, hash]
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

  #生成order的code
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
