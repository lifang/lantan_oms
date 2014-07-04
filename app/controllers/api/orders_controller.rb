#encoding: utf-8
class Api::OrdersController < ApplicationController
  #  登录
  def login
    name = params[:user_name]
    pwd = params[:user_password]
    status = 1
    msg = ""
    obj = {}
    staff = Staff.find_by_username_and_status(name, Staff::STATUS[:normal])
    if staff.nil?
      status = 0
      msg = "用户不存在或者用户状态异常"
    else
      if staff.has_password?(pwd) == false
        status = 0
        msg = "密码错误!"
      else
        store = Store.find_by_id(staff.store_id) if staff.store_id
        if store.nil? || store.status != Store::STATUS[:OPENED]
          status = 0
          msg = "门店不存在或不在营业!"
        else
          if staff.type_of_w == Staff::S_COMPANY[:BOSS] || staff.type_of_w == Staff::S_COMPANY[:CHIC] || staff.type_of_w == Staff::S_COMPANY[:FRONT]
            begin
              posi = Department.find_by_id(staff.department_id)
              dpt = Department.find_by_id(staff.position)
              obj[:user_info] = {:user_id => staff.id, :username => staff.username, :photo => staff.photo,
                :position => posi.nil? ? "" : posi.name, :department => dpt.nil? ? "" : dpt.name,
                :cash_auth => store.cash_auth, :name => staff.name, :store_id => store.id, :store_name => store.name}
              obj[:carInfo] = {:capital_arr => Capital.get_car_sort}
            rescue
              status = 0
              msg = "数据错误!"
            end
          else
            status = 0
            msg = "没有权限!"
          end
        end
      end
    end
    render :json => {:status => status, :msg => msg, :obj => obj}
  end


  #用户界面（个人信息，订单列表）
  def user_and_order
    status,msg,order_count,has_pay,orders_now = Staff.staff_and_order params[:user_id],params[:store_id]
    render :json => {:status => status, :msg => msg, :obj => {:order_count => order_count,:has_pay=> has_pay,:orders_now => orders_now}}
  end

  #预约列表
  def reservation_list
    status, msg, nor_array, accpted_array = Reservation.store_reservations params[:store_id]
    render :json =>{:status => status, :msg => msg, :obj => {:reservations_normal => nor_array, :reservations_accepted => accpted_array}}
  end

  #拒绝,受理,取消预约
  def reservation_isaccept
    status,msg, obj = Reservation.is_accept params[:reservation_id],params[:store_id],params[:types]
    render :json => {:status =>  status,:notice =>msg, :obj => obj}
  end

  #点击开单 显示右边的快速选择产品或服务
  def enter_order
    status, msg, products = Product.products_and_services params[:store_id]
    render :json => {:status => status, :msg => msg, :obj => {:products => products}}
  end

  #产品（产品列表）搜索
  def products_list   #types 0为产品 1为服务 2为卡类
    status,msg,cards, services, products = Product.products_arr params[:store_id].to_i,params[:product_name],params[:types].to_i
    render :json => {:status => status, :msg => msg, :obj => {:cards => cards, :services => services, :products => products}}
  end

  #根据车牌号或者手机号码查询客户
  def search_car
    status, msg, hash = Order.search_by_car_num params[:store_id].to_i,params[:car_num], params[:is_car_num].to_i,params[:type].to_i
    render :json => {:status => status, :msg => msg, :obj => hash}
  end
  
  #在查询客户时点击进行中的订单，消费记录，套餐卡，储值卡等
  def search_customers_datas
    store_id,customer_id,type,car_num_id = params[:store_id].to_i, params[:customer_id].to_i, params[:type].to_i, params[:car_num_id].to_i
    status = 1
    msg = ""
    array = []
    hash = {}
    begin
      if type == 0  #查看该客户某辆车正在消费的订单
        array = Customer.get_customer_working_orders customer_id, car_num_id
        hash[:working_orders] = array
      elsif type == 1 #查看该客户某辆车的消费记录
        array = Customer.get_customer_order_records customer_id, car_num_id
        hash[:old_orders] = array
      elsif type == 2 #查看该客户的所有套餐卡
        array = Customer.get_customer_package_cards customer_id
        hash[:package_cards] = array
      elsif type == 3 #查看该客户的所有的储值卡
        array = Customer.get_customer_sv_cards customer_id
        hash[:sv_cards] = array
      elsif type == 4 #查看该客户的所有的打折卡
        array = Customer.get_customer_dis_cards customer_id
        hash[:discount_cards] = array
      end
    rescue
      status = 0
      msg = "数据错误!"
    end
    render :json => {:status => status, :msg => msg, :obj => hash}
  end

  #投诉
  def complaint_order
    status, msg = Complaint.mk_record(params[:reason], params[:request], params[:store_id].to_i, params[:order_id].to_i)
    render :json => {:status => status, :msg => msg, :obj => {}}
  end


  #取消订单
  def cancel_order
    status = 1
    msg = ""
    work_orders = nil
    begin
      Order.transaction do
        order = Order.find_by_id(params[:order_id].to_i)
        cus_pcards = CustomerCard.where(["types=? and order_id=?", CustomerCard::TYPES[:PACKAGE], order.id])
        oprs = OrderProdRelation.where(["order_id=? and prod_types=?", order.id, OrderProdRelation::PROD_TYPES[:SERVICE]])
        cus_pcards.each do |cus_pcard|  #如果是买的套餐卡，则要把产品相应的库存给补上
          pprs = PcardProdRelation.where(["packag_card_id=?", cus_pcard.card_id])
          pprs.each do |ppr|
            prod = Product.find_by_id(ppr.product_id)
            prod.update_attribute("storage", prod.storage.to_f.round(2) + ppr.product_num.to_f.round(2)) if !prod.is_service
          end if pprs.any?
        end if cus_pcards.any?
        oprs.each do |opr|  #如果是产品的订单,也要把产品对应的库存补上
          product = Product.find_by_id(opr.item_id)
          if !product.is_service  #如果是产品,则直接补上库存
            product.update_attribute("storage", product.storage.to_f.round(2) + opr.pro_num.to_f.round(2))
          end
        end if oprs.any?
        order.update_attributes(:status => Order::STATUS[:RETURN], :return_types => Order::IS_RETURN[:YES])
        order.work_orders.inject([]){|h,wo| wo.update_attribute("status", WorkOrder::STAT[:CANCELED])}
        Station.arrange_work_orders params[:store_id].to_i
        work_orders = working_orders params[:store_id]
      end
    rescue
      status = 0
      msg = "数据错误!"
    end
    render :json => {:status => status, :msg => msg, :obj => {:work_orders => work_orders}}
  end

  def working_orders (store_id)
    orders = Order.working_orders store_id.to_i   #等待、施工中、待付款的订单
    orders = combin_orders(orders)
    orders = new_app_order_by_status(orders)
    orders
  end

  def combin_orders(orders)
    orders.map{|order|
      work_order = WorkOrder.find_by_order_id(order.id)
      service_name = Order.find_by_sql("select p.name p_name from orders o inner join order_prod_relations opr on opr.order_id=o.id inner join
            products p on p.id=opr.product_id where (p.is_service=#{Product::PROD_TYPES[:SERVICE]} or p.is_added =#{Product::IS_ADDED[:YES]})
           and o.id = #{order.id}").map(&:p_name).compact.uniq
      order[:wo_started_at] = (work_order && work_order.started_at && work_order.started_at.strftime("%Y-%m-%d %H:%M:%S")) || ""
      order[:wo_ended_at] = (work_order && work_order.ended_at && work_order.ended_at.strftime("%Y-%m-%d %H:%M:%S")) || ""
      order[:car_num] = order.car_num.try(:num)
      order[:service_name] = service_name.join(",")
      order[:cost_time] = work_order.try(:cost_time)
      order[:station_id] = work_order.try(:station_id)
      order[:order_id] = order.try(:id)
      order[:c_pcard_relation_id] = order.try(:c_pcard_relation_id)
    }
    orders
  end

  #新的app，order分组，把已付款，但是施工中的放在施工中
  def new_app_order_by_status(orders)
    order_hash = {}
    order_hash[Order::STATUS[:WAIT_PAYMENT]] = orders.select{|order| order.status == Order::STATUS[:WAIT_PAYMENT] || order.status == Order::STATUS[:PCARD_PAY]}
    order_hash[WorkOrder::STAT[:WAIT]] = orders.select{|order| order.wo_status == WorkOrder::STAT[:WAIT]}
    order_hash[WorkOrder::STAT[:SERVICING]] = orders.select{|order| order.wo_status == WorkOrder::STAT[:SERVICING]}
    s_staffs = TechOrder.joins(:staff,:order=>:work_orders).select("work_orders.station_id,staffs.name,tech_orders.staff_id").
      where(:"tech_orders.order_id"=>order_hash[WorkOrder::STAT[:SERVICING]].map(&:order_id),:"staffs.store_id"=>params[:store_id]).group_by{|i|i.station_id}.values
    order_hash[:used_staffs] = s_staffs
    order_hash
  end


end
