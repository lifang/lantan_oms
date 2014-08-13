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

  #下单
  def make_order
    status, msg = 1, ""
    begin
      Customer.transaction do
        customer_id = params[:customer_id]
        car_num_id = params[:car_num_id]
        prods = params[:prods].split(",")
        customer, car_num = nil, nil
        order_prods_ids, by_pcard_buy, order_prods, order = [], [], [], nil
        if customer_id.nil? || car_num_id.nil?  #是新创建的客户
          #判断用户名或者电话号码是否重复
          cus_status, cus_msg = Customer.customer_valid([params[:num]], params[:store_id].to_i, 0, params[:name],
            params[:mobilephone])
          if cus_status == 0  #用户名或者电话号码重复，则不创建
            status = 0
            msg = cus_msg
          else
            #创建新客户
            salt = Digest::MD5.hexdigest(Time.now.strftime("%Y%m%d%H%M%S"))
            cus_hash = {:name => params[:name], :mobilephone => params[:mobilephone],
              :sex => params[:sex].to_i==0 ? false : true, :is_vip => false, :status => Customer::STATUS[:NOMAL],
              :types => Customer::TYPES[:NORMAL], :username => params[:mobilephone], :property => params[:property].to_i,
              :group_name => params[:property].to_i==0 ? nil : params[:group_name],
              :allowed_debts => Customer::ALLOWED_DEBTS[:NO], :store_id => params[:store_id].to_i,
              :salt => salt, :encrypted_password => Digest::MD5.hexdigest("000000#{salt}")}
            customer = Customer.create(cus_hash)
            car_num = CarNum.create(:num => params[:num], :car_model_id => params[:model_id].to_i,
              :buy_year => params[:year].to_i, :distance => params[:distance].to_i, :vin_code => params[:vin])
            CustomerNumRelation.create(:customer_id => customer.id, :car_num_id => car_num.id, :store_id => params[:store_id].to_i)
            order_prods_ids, by_pcard_buy, order_prods, order, actual_price = Customer.make_order(customer.id, car_num.id, params[:store_id].to_i, params[:user_id].to_i, prods)
          end
        else
          customer = Customer.find_by_id(customer_id.to_i)
          car_num = CarNum.find_by_id(car_num_id.to_i)
          cus_status, cus_msg = Customer.customer_valid([params[:num]], params[:store_id].to_i, 1, params[:name],
            params[:mobilephone], customer.id)
          if cus_status == 0  #用户名或者电话号码重复，则不编辑
            status = 0
            msg = cus_msg
          else
            cus_hash = {:name => params[:name], :mobilephone => params[:mobilephone],
              :sex => params[:sex].to_i==0 ? false : true, :property => params[:property].to_i,
              :group_name => params[:property].to_i==0 ? nil : params[:group_name],}
            customer.update_attributes(cus_hash)
            car_hash = {:num => params[:num], :car_model_id => params[:model_id].to_i,
              :buy_year => params[:year].to_i, :distance => params[:distance].to_i, :vin_code => params[:vin]}
            car_num.update_attributes(car_hash)
            order_prods_ids, by_pcard_buy, order_prods, order, actual_price = Customer.make_order(customer.id, car_num.id, params[:store_id].to_i, params[:user_id].to_i, prods)
          end
        end
        if status == 1
          #返回客户的储值卡
          sv_cards = CustomerCard.get_customer_save_cards_by_products customer.id, order_prods_ids.compact.uniq
          #返回客户的打折卡
          dis_cards = CustomerCard.get_customer_discount_cards_by_products customer.id, order_prods_ids.compact.uniq
          #返回客户的套餐卡
          p_cards = CustomerCard.get_customer_package_cards_by_products customer.id, order_prods_ids.compact.uniq, by_pcard_buy
          #返回活动
          sales = Sale.get_customer_sales_by_products params[:store_id].to_i, order_prods_ids.compact.uniq
          #客户信息
          customer_info = {:name => customer.name, :phone => customer.mobilephone, :code => order.code, :car_num => car_num.num,
            :car_num_id => car_num.id, :created_time => order.created_at.strftime("%Y-%m-%d %H:%M"), :status => order.status,
            :total_price => actual_price, :customer_id => customer.id, :order_id => order.id }
          prods_name = []
          order_prods.each do |hash|
            prods_name << hash[:name]
          end
          customer_info[:pro_name] = prods_name.join(",")
        end
        render :json => {:status => status, :msg => msg, :obj => {:products => order_prods, :customer => customer_info,
            :work_orders => app_working_orders(params[:store_id].to_i), :save_cards => sv_cards, :sales => sales,
            :p_cards => p_cards, :discount_cards => dis_cards}}
      end
    rescue
      status = 0
      msg = "数据错误!"
      render :json => {:status => status, :msg => msg, :obj => {:products => nil, :customer => nil,
          :work_orders => nil, :save_cards => nil, :sales => nil,
          :p_cards => nil, :discount_cards => nil}}
    end
  end

  #客户信息-未付款订单点击付款
  def make_order2
    order_id, store_id = params[:order_id].to_i, params[:store_id].to_i
    status, msg = 1, ""
    begin
      Order.transaction do
        order = Order.find_by_id(order_id)
        customer = Customer.find_by_id(order.customer_id)
        car_num = CarNum.find_by_id(order.car_num_id)
        prods = OrderProdRelation.where(["order_id=?", order.id])
        prod_ids_array = []   #产品或服务的id
        by_pcard_buy = [] #通过套餐卡下单的选项
        prods_and_cards = [] #该订单所有的产品、服务及卡类
        actual_price = 0  #实际需要付款的价格
        prods.each do |p|
          if p.prod_types == OrderProdRelation::PROD_TYPES[:SERVICE]  #如果是产品或服务
            prod_ids_array << p.item_id.to_i
            by_pcard_buy << {:customer_pcard_id => p.customer_pcard_id, :product_id => p.item_id, :num => p.pro_num} if p.customer_pcard_id && p.customer_pcard_id.to_i!=0
            actual_price = actual_price + p.total_price.to_f.round(2) if p.customer_pcard_id.nil?
          elsif p.prod_types == OrderProdRelation::PROD_TYPES[:P_CARD]  #如果是套餐卡
            p_card = PackageCard.find_by_id(p.item_id)
            prods_and_cards << {:id => p_card.id, :name => p_card.name, :price =>p_card.price.to_f.round(2),
              :total_price => p_card.price.to_f.round(2), :num => 1, :type => 2, :valid_num => 1}
            actual_price = actual_price + p.total_price.to_f.round(2)
          elsif p.prod_types == OrderProdRelation::PROD_TYPES[:P_CARD]  #如果是打折卡或储值卡
            sv_card = SvCard.find_by_id(p.item_id)
            prods_and_cards << {:id => sv_card.id, :name => sv_card.name, :price =>sv_card.price.to_f.round(2),
              :total_price => sv_card.price.to_f.round(2), :num => 1, :type => 2, :valid_num => 1}
            actual_price = actual_price + p.total_price.to_f.round(2)
          end
        end if prods.any?
        #筛选出产品和服务(用来判断其中套餐卡下的次数)
        product_and_service_hash = prods.select{|prod| prod.prod_types=OrderProdRelation::PROD_TYPES[:SERVICE]}.group_by{|prod| prod.item_id}
        product_and_service_hash.each do |prod_id, prod_arr|
          product = Product.find_by_id(prod_id.to_i)
          all_num, by_pcard_num = 0, 0
          prod_arr.each do |pa|
            all_num = all_num + pa.pro_num
            by_pcard_num = by_pcard_num + pa.pro_num if pa.customer_pcard_id.nil? == false && pa.customer_pcard_id.to_i!=0
          end
          prods_and_cards << {:id => product.id, :name => product.name, :price => product.sale_price.to_f.round(2),
            :total_price => (product.sale_price.to_f.round(2) * all_num).round(2),
            :num => all_num, :type => product.is_service ? 1 : 0, :valid_num => all_num == by_pcard_num ? 0 : all_num - by_pcard_num}
        end
        #客户的储值卡、打折卡、套餐卡、活动及客户信息
        sv_cards = CustomerCard.get_customer_save_cards_by_products customer.id, prod_ids_array.compact.uniq
        dis_cards = CustomerCard.get_customer_discount_cards_by_products customer.id, prod_ids_array.compact.uniq
        p_cards = CustomerCard.get_customer_package_cards_by_products customer.id, prod_ids_array.compact.uniq, by_pcard_buy
        sales = Sale.get_customer_sales_by_products store_id, prod_ids_array.compact.uniq
        customer_info = {:name => customer.name, :phone => customer.mobilephone, :code => order.code, :car_num => car_num.num,
          :car_num_id => car_num.id, :created_time => order.created_at.strftime("%Y-%m-%d %H:%M"), :status => order.status,
          :total_price => actual_price, :customer_id => customer.id, :order_id => order.id }
        prods_name = []
        prods_and_cards.each do |hash|
          prods_name << hash[:name]
        end
        customer_info[:pro_name] = prods_name.join(",")
        render :json => {:status => status, :msg => msg, :obj => {:products => prods_and_cards, :customer => customer_info,
            :save_cards => sv_cards, :sales => sales, :p_cards => p_cards, :discount_cards => dis_cards}}
      end
    rescue
      status = 0
      msg = "数据错误!"
      render :json => {:status => status, :msg => msg, :obj => {:products => nil, :customer => nil,
          :work_orders => nil, :save_cards => nil, :sales => nil,
          :p_cards => nil, :discount_cards => nil}}
    end
  end

  #取消订单(暂时不用 留着)
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
        work_orders = app_working_orders params[:store_id]
      end
    rescue
      status = 0
      msg = "数据错误!"
    end
    render :json => {:status => status, :msg => msg, :obj => {:work_orders => work_orders}}
  end

  #退单
  def back_order
    status, msg = 1, ""
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
        ReturnOrder.create(:return_types => 5, :order_id => order.id, :store_id => params[:store_id])
        order.update_attributes(:status => Order::STATUS[:RETURN], :return_types => Order::IS_RETURN[:YES])
        order.work_orders.inject([]){|h,wo| wo.update_attribute("status", WorkOrder::STAT[:CANCELED])}
        Station.arrange_work_orders params[:store_id].to_i
        work_orders = app_working_orders params[:store_id].to_i
      end
    rescue
      status = 0
      msg = "数据错误!"
    end
    render :json => {:status => status, :msg => msg, :obj => {:work_orders => work_orders}}
  end
  
  #订单付款
  def pay_order
    status = 1
    msg =""
    work_orders = {}
    begin
      billing,is_free,pay_type = params[:billing].to_i, params[:is_free].to_i, params[:pay_type].to_i
      Order.transaction do
        order = Order.find_by_id(params[:order_id].to_i)
        status, msg = Customer.pay_order(order, params[:is_please].to_i, params[:prods], params[:total_price].to_f.round(2),
          1, params[:pic], billing, is_free, pay_type, params[:password], params[:csrid])
        work_orders = app_working_orders params[:store_id]
      end
    rescue
      status = 0
      msg = "数据错误!"
    end
    render :json => {:status => status, :msg => msg, :obj => {:work_orders => work_orders}}
  end

  #没有收银权限的时候的订单付款
  def pay_order_no_auth
    status = 1
    msg =""
    begin
      Order.transaction do
        order = Order.find_by_id(params[:order_id].to_i)
        status, msg = Customer.pay_order(order, params[:is_please].to_i, params[:prods], params[:total_price].to_f.round(2),
          0, params[:pic], nil, nil, nil, nil, nil)
      end
    rescue
      status = 0
      msg = "数据错误!"
    end
    render :json => {:status => status, :msg => msg, :obj => {}}
  end

  #修改储值卡密码,发送验证码
  def set_svcard_pwd_send_code
    status, msg = 1, ""
    begin
      CustomerCard.transaction do
        cus_card = CustomerCard.find_by_id(params[:cid].to_i)
        customer = Customer.find_by_id(cus_card.customer_id)
        cus_card.update_attribute("verify_code", proof_code(6).downcase)
        send_message = [{:content => "本次验证码：#{cus_card.verify_code}", :msid => customer.id,
            :mobile => customer.mobilephone}]
        msg_hash = {:resend => 0, :list => send_message ,:size => send_message.length}
        jsondata = JSON msg_hash
        message_route = "/send_packet.do?Account=#{SendMessage::USERNAME}&Password=#{SendMessage::PASSWORD}&jsondata=#{jsondata}&Exno=0"
        create_get_http(SendMessage::MESSAGE_URL, message_route)
      end
    rescue
      status = 0
      msg = "发送失败"
    end
    render :json => {:status => status, :msg => msg, :obj => {}}
  end

  #修改储值卡密码 提交
  def set_svcard_pwd_commit
    cus_card_id, v_code, new_pwd = params[:cid].to_i, params[:verify_code], params[:n_password]
    status, msg = 1, ""
    begin
      CustomerCard.transaction do
        cus_card = CustomerCard.find_by_id(cus_card_id)
        old_code =  cus_card.verify_code
        if old_code != v_code
          status = 0
          msg = "验证码错误!"
        else
          cus_card.update_attribute("password", Digest::MD5.hexdigest(new_pwd))
        end
      end
    rescue
      status = 0
      msg = "数据错误!"
    end
    render :json => {:status => status, :msg => msg, :obj => {}}
  end

  #同步pad数据
  def pad_sync
    status, msg = 1, ""
    sync_arr = Json.parse(params[:syncInfo])
    store_id = params[:store_id].to_i
    work_orders = nil
    begin
      Order.transaction do
        sync_arr.each do |hash|
          if hash["status"].to_i == 2   #投诉
            reason = hash["reason"]
            request = hash["request"]
            order_id = hash["order_id"].to_i
            Complaint.mk_record(reason, request, store_id, order_id)
          elsif hash["status"].to_i == 1   #付款
            billing,is_free,pay_type = hash["billing"].to_i, hash["is_free"].to_i, hash["pay_type"].to_i
            order = Order.find_by_id(hash["order_id"].to_i)
            Customer.pay_order(order, hash["is_please"].to_i, hash["prods"], hash["total_price"].to_f.round(2),
              1, nil, billing, is_free, pay_type, nil, nil)
          elsif hash["status"].to_i == 7 || hash["status"].to_i == 9  #取消订单或者退单
            order_id = hash["order_id"].to_i
            order = Order.find_by_id(order_id)
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
            Station.arrange_work_orders store_id
            if hash["status"].to_i == 9 #如果是退单 则要创建退单记录
              ReturnOrder.create(:return_types => 5, :order_id => order.id, :store_id => store_id)
            end
          end
        end
        work_orders = app_working_orders params[:store_id].to_i
      end
    rescue
      status = 0
      msg = "数据错误!"
    end
    render :json => {:status => status, :msg => msg, :obj => {:work_orders => work_orders}}
  end

  #施工现场
  def app_working_orders (store_id)
    orders = Order.working_orders store_id.to_i   #等待、施工中、待付款,已付款未施工或正在施工的订单
    wait, serving, wait_pay = [], [], []
    orders.each do |o|
      if o.status == Order::STATUS[:NORMAL] #等待施工
        hash = working_orders_prods o
        hash[:station_id] = nil
        hash[:serving] = nil
        hash[:started_at] = nil
        hash[:ended_at] = nil
        hash[:cost_time] = nil
        hash[:work_order_id] = nil
        wait << hash
      elsif o.status == Order::STATUS[:SERVICING] #正在施工
        hash = working_orders_prods o
        serving_work_order = WorkOrder.find_by_sql(["select wo.*, p.name pname from work_orders wo inner join products p on wo.service_id=p.id
            where wo.order_id=? and wo.status=?", o.id, WorkOrder::STAT[:SERVICING]]).first
        hash[:station_id] = serving_work_order.station_id
        hash[:serving] = serving_work_order.pname
        hash[:started_at] = serving_work_order.started_at
        hash[:ended_at] = serving_work_order.ended_at
        hash[:cost_time] = serving_work_order.cost_time.to_i
        hash[:work_order_id] = serving_work_order.id
        serving << hash
      elsif o.status == Order::STATUS[:WAIT_PAYMENT] #等待付款
        hash = working_orders_prods o
        hash[:station_id] = nil
        hash[:serving] = nil
        hash[:started_at] = nil
        hash[:ended_at] = nil
        hash[:cost_time] = nil
        hash[:work_order_id] = nil
        wait_pay << hash
      elsif o.status == Order::STATUS[:BEEN_PAYMENT] #已付款 但还没施工或正在施工
        serving_work_order = WorkOrder.find_by_sql(["select wo.*, p.name pname from work_orders wo inner join products p on wo.service_id=p.id
            where wo.order_id=? and wo.status=?", o.id, WorkOrder::STAT[:SERVICING]]).first
        if serving_work_order   #说明该订单已付款但是还在施工
          hash = working_orders_prods o
          hash[:station_id] = serving_work_order.station_id
          hash[:serving] = serving_work_order.pname
          hash[:started_at] = serving_work_order.started_at.strftime("%y-%m-%d %H:%M")
          hash[:ended_at] = serving_work_order.ended_at.strftime("%y-%m-%d %H:%M")
          hash[:cost_time] = serving_work_order.cost_time.to_i
          hash[:work_order_id] = serving_work_order.id
          serving << hash
        else
          wait_work_order = WorkOrder.find_by_sql(["select wo.*, p.name pname from work_orders wo inner join products p on wo.service_id=p.id
            where wo.order_id=? and wo.status=?", o.id, WorkOrder::STAT[:WAIT]])
          if wait_work_order.any?   #说明该订单已付款但是等待施工
            hash = working_orders_prods o
            hash[:station_id] = nil
            hash[:serving] = nil
            hash[:started_at] = nil
            hash[:ended_at] = nil
            hash[:cost_time] = nil
            hash[:work_order_id] = nil
            wait << hash
          end
        end
      end
    end
    return {0 => wait, 1 => serving, 2 => wait_pay}
  end

  #获取施工现场的订单的客户信息及产品和卡
  def working_orders_prods  order
    hash = {:code => order.code, :customer_name => order.cname, :customer_id => order.cuid, :car_num => order.cnum, :car_num_id => order.cnid, :mobilephone => order.cphone,
      :car_brand => order.brand_name, :car_model => order.model_name, :buy_year => order.buy_year, :customer_property => order.property.to_i, :customer_sex => order.csex.to_i,
      :vin_code => order.vin_code, :distance => order.distance.to_i, :group_name => order.group_name, :order_id => order.id}
    prods = []
    total_price = 0
    order_prods = OrderProdRelation.find_by_sql(["select opr.*, p.name pname from order_prod_relations opr inner join products p on opr.item_id=p.id
            where opr.order_id=? and opr.prod_types=?", order.id, OrderProdRelation::PROD_TYPES[:SERVICE]]).group_by{|op| op.item_id}
    order_pcards = OrderProdRelation.find_by_sql(["select opr.*, pcard.name pname from order_prod_relations opr inner join package_cards pcard on opr.item_id=pcard.id
                where opr.order_id=? and opr.prod_types=?", order.id, OrderProdRelation::PROD_TYPES[:P_CARD]])
    order_svcards = OrderProdRelation.find_by_sql(["select opr.*, svcard.name svname from order_prod_relations opr inner join sv_cards svcard on opr.item_id=svcard.id
                where opr.order_id=? and opr.prod_types=?", order.id, OrderProdRelation::PROD_TYPES[:SV_CARD]])
    order_prods.each do |item_id, arr|
      op_hash = {:product_id => item_id}
      arr.each do |prod|
        op_hash[:product_name] = prod.pname
        op_hash[:price] = prod.price.to_f.round(2)
        op_hash[:product_num] = op_hash[:product_num].nil? ? prod.pro_num.to_i : op_hash[:product_num].to_i + prod.pro_num.to_i
        op_hash[:total_price] = op_hash[:total_price].nil? ? prod.total_price.to_f.round(2) : op_hash[:total_price].to_f.round(2) + prod.total_price.to_f.round(2)
        total_price = total_price + prod.total_price.to_f.round(2)
      end
      prods << op_hash
    end
    order_pcards.each do |pcard|
      op_hash = {:product_id => pcard.item_id, :product_name => pcard.pname, :price => pcard.price, :product_num => pcard.pro_num,
        :total_price => pcard.total_price}
      prods << op_hash
      total_price = total_price + pcard.total_price.to_f.round(2)
    end
    order_svcards.each do |os|
      op_hash = {:product_id => os.item_id, :product_name => os.svname, :price => os.price, :product_num => os.pro_num,
        :total_price => os.total_price}
      prods << op_hash
      total_price = total_price + os.total_price.to_f.round(2)
    end
    hash[:products] = prods
    hash[:total_price] = total_price
    return hash
  end
end
