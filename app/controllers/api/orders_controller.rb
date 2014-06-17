#encoding: utf-8
class Api::OrdersController < ApplicationController
  #  登录
  def login
    staff = Staff.find_by_username(params[:user_name])
    info = ""
    status = 0
    if  staff.nil? or !staff.has_password?(params[:user_password])
      info = "用户名或密码错误"
    elsif !Staff::VALID_STATUS.include?(staff.status)
      info = "用户不存在"
    else
      cookies[:user_id]={:value => staff.id, :path => "/", :secure  => false}
      cookies[:user_name]={:value =>staff.name, :path => "/", :secure  => false}
      session_role(cookies[:user_id])
      if has_authority?
        info = ""
        status
      else
        cookies.delete(:user_id)
        cookies.delete(:user_name)
        cookies.delete(:user_roles)
        cookies.delete(:model_role)
        info = "抱歉，您没有访问权限"
      end
    end
    capital_arr = Order.get_car_sort
    render :json => {:staff => staff, :status => status ,:info => info,:capital_arr => capital_arr}
  end

  #登录后返回数据
  def new_index_list
    #参数store_id
    status = 0
    #订单分组
    work_orders = working_orders params[:store_id]
    
    #stations_count => 工位数目
    station_ids = Station.where("store_id =? and status not in (?) ",params[:store_id], [Station::STAT[:WRONG], Station::STAT[:DELETED]]).select("id, name")
    services = Product.is_service.is_normal.where(:store_id => params[:store_id]).select("id, name, sale_price as price")
    reservations = Reservation.store_reservations params[:store_id]
    render :json => {:status => status, :orders => work_orders, :station_ids => station_ids, :services => services,:reservations=>reservations}
  end

  #  #首页,登录后的页面  施工现场
  #  def index_list
  #    status = 0
  #    begin
  #      reservations = Reservation.store_reservations params[:store_id]
  #      of_waiting,stations_order,of_completed,products = Order.working_orders params[:store_id]
  #      status = 1
  #    rescue
  #      status = 2
  #    end
  #    render :json => {:status => status,:of_waiting => of_waiting,:stations_order=> stations_order,:of_completed=> of_completed,
  #      :reservations => reservations,:products=>products}
  #  end

  #用户界面（个人信息，订单列表）
  def user_and_order
    order_count,has_pay,orders_now = Staff.staff_and_order params[:staff_id],params[:store_id]
    render :json => {:order_count => order_count,:has_pay=> has_pay,:orders_now => orders_now}
  end
  #施工现场
  def construction_site
    work_orders = working_orders params[:store_id]
    station_ids = Station.station_service params[:store_id]
    #    station_ids = Station.where("store_id =? and status not in (?) ",params[:store_id], [Station::STAT[:WRONG], Station::STAT[:DELETED]]).select("id, name")
    services = Product.is_service.is_normal.where(:store_id => params[:store_id]).where(:show_on_ipad => Product::SHOW_ON_IPAD[:YES]).select("id, name, sale_price as price")
    render :json =>{:work_orders=>work_orders,:station_ids=>station_ids,:services=>services}
  end

  #现场管理-订单详情
  def order_details
    order_details = Order.order_details params[:order_id]
    render :json => {:order_details=>order_details}
  end

  #预约列表
  def reservation_list
    reservations_normal,reservations_accepted = Reservation.store_reservations params[:store_id]
    notice = reservations_normal.blank?&&reservations_accepted.blank? ? "无预约信息" : "返回预约列表"
    render :json =>{:notice=>notice,:reservations_normal=> reservations_normal,:reservations_accepted=>reservations_accepted}
  end

  #拒绝,受理,取消预约
  def reservation_isaccept
    status,notice = Reservation.is_accept params[:reservation_id],params[:store_id],params[:types]
    render :json => {:status =>  status,:notice =>notice }
  end

  #进入下单界面或搜索产品
  def enter_order
    product_name = params[:name].nil? || params[:name].strip == "" ? "%%" : "%"+ params[:name] +"%"
    products = Product.products_and_services params[:store_id],product_name
    render :json => {:products => products}
  end

  #产品（产品列表）搜索
  def products_list
    status = 0
    product_name = params[:product_name].nil? || params[:product_name].strip == "" ? "%%" : "%"+ params[:product_name] +"%"
    if params[:store_id] && product_name
      status = 1
      cards,services, products = Product.products_arr params[:store_id],product_name,params[:types]
    end
    render :json=>{:status => status,:cards=>cards,:services=>services,:products=>products,:types=>params[:types]}
  end

  #根据车牌号或者手机号码查询客户你昨天说的那个优酷上的视频叫什么名字？
  def search_car
    order,customer_cards,discount_cards,stored_cards = Order.search_by_car_num params[:store_id],params[:car_num],params[:types]
    result = {:status => 1,:customer => order,:customer_cards => customer_cards,:discount_cards=>discount_cards,:stored_cards => stored_cards}
    render :json => result
  end


  #点击完成按钮，确定选择的产品和服务
  def finish
    prod_id = params[:prod_ids] #"10_3,311_0,226_2,"
    prod_id = prod_id[0...(prod_id.size-1)] if prod_id
    pre_arr = Order.pre_order params[:store_id],params[:carNum],params[:brand],params[:year],params[:userName],params[:phone],
      params[:email],params[:birth],prod_id,params[:res_time],params[:sex], params[:from_pcard].to_i
    content = ""
    if pre_arr[5] == 0
      content = "数据出现异常"
    elsif pre_arr[5] == 1
      content = "success"
    elsif pre_arr[5] == 2
      content = "选择的产品和服务无法匹配工位"
    elsif pre_arr[5] == 3
      content = "所购买的服务需要多个工位，请分别下单！"
    elsif pre_arr[5] == 4
      content = "工位上暂无技师"
    end
    result = {:status => pre_arr[5], :info => pre_arr[0], :products => pre_arr[1], :sales => pre_arr[2],
      :svcards => pre_arr[3], :pcards => pre_arr[4], :total => pre_arr[6], :content  => content}
    render :json => result.to_json
  end
  #下单
  def add
    #查询出来的用户为1，手动输入的用户为0
    #name姓名 car_num车牌号 mobilephone手机号码 car_model_name车品牌 car_brand_name车型 buy_year购买年份 property属性 sex性别 vin maint_distance里程 group_name公司名称
    status=1
    if params[:type].to_i == 1
      status, msg = Customer.customer_valid params[:car_num],params[:store_id],params[:type],params[:name],params[:mobilephone]  #新建或编辑客户时验证
      if status == 1
        begin
          store_id = params[:store_id]
          name = params[:name]
          car_num = params[:car_num]
          mobilephone = params[:mobilephone]
          sex = params[:sex]
          is_vip = params[:cus_is_vip].nil? || params[:cus_is_vip].to_i==0 ? 0 : 1
          property = params[:cus_property].to_i
          group_name = property==0 || params[:group_name].nil? || params[:group_name]=="" ? nil : params[:group_name]
          store_id = params[:store_id]
          car_model_id = params[:car_model_id]
          buy_year = params[:buy_year]
          distance = params[:maint_distance]
          salt = Digest::MD5.hexdigest(Time.now.strftime("%Y%m%d%H%M%S"))
          Customer.transaction do
            customer = Customer.new(:name=>name,:mobilephone => mobilephone,:sex => sex, :status => Customer::STATUS[:NOMAL],:types => Customer::TYPES[:NORMAL],
              :username => name,:is_vip => is_vip, :group_name => group_name, :property => property, :store_id => store_id, :salt => salt)
            customer.encrypted_password = Digest::MD5.hexdigest("888888#{salt}")
            customer.save
            car_num =  CarNum.create(:num => car_num,:car_model_id=>car_model_id, :buy_year => buy_year,:distance =>distance)
            CustomerNumRelation.create(:customer_id => customer.id, :car_num_id => car_num.id, :store_id => store_id)
          end
        rescue
          status = 0
          msg = "创建不成功！"
        end
      end
    end
    if status == 1
      user_id = params[:user_id].nil? ? cookies[:user_id] : params[:user_id]
      order = Order.make_record params[:c_id],params[:store_id],params[:car_num_id],params[:start],
        params[:end],params[:prods],params[:price],params[:station_id],user_id
      info = order[1].nil? ? nil : order[1].get_info
      str = if order[0] == 0 || order[0] == 2
        "数据出现异常"
      elsif order[0] == 1
        "success"
      elsif order[0] == 3
        "没可用的工位了"
      end
      render :json => {:status => order[0], :content => str, :order => info}
    else
      render :json => {:status=>status,:msg=>msg}
    end
  end

  #查询订单后的支付，取消订单
  def pay_order
    order = Order.find_by_id params[:order_id]
    info = order.nil? ? nil : order.get_info
    status = 0
#    if params[:opt_type].to_i == 1
      if order && (order.status == Order::STATUS[:NORMAL] or order.status == Order::STATUS[:SERVICING] or order.status == Order::STATUS[:WAIT_PAYMENT])
        #退回使用的套餐卡次数
        order.return_order_pacard_num
        #如果是产品,则减掉要加回来
        order.return_order_materials
        #如果存在work_order,取消订单后设置work_order以及wk_or_times里面的部分数值
        order.rearrange_station
        order.update_attribute(:status, Order::STATUS[:DELETED])
        status = 1
      else
        status = 2
      end
      #    else
    #      status = 1
    #    end
    orders = working_orders params[:store_id]
    render :json  => {:status => status, :order => info,:orders => orders}
  end

  #施工完成 -> 等待付款
  def work_order_finished
    #work_order_id
    work_order = WorkOrder.find_by_id(params[:work_order_id])
    if work_order
      if work_order.status==WorkOrder::STAT[:WAIT_PAY]
        status = 0
        #"此车等待付款"
      else
        status = 1
        # "操作成功"
        work_order.arrange_station
      end
    else
      #"工单未找到"
      status = 2
    end
    work_orders = working_orders params[:store_id]
    render :json => {:status => status, :orders => work_orders}
  end

  #付款
  def pay
    #满意度，支付方式，是否寄出，订单码，免单，
    order = Order.pay(params[:order_id], params[:store_id], params[:please],
      params[:pay_type], params[:billing], params[:code], params[:is_free])
    content = ""
    if order[0] == 0
      content = ""
    elsif order[0] == 1
      content = "success"
    elsif order[0] == 2
      content = "订单不存在"
    elsif order[0] == 3
      content = "储值卡余额不足，请选择其他支付方式"
    end
    render :json => {:status => order[0], :content => content}
  end

  #预约排单
  def confirm_reservation
    reservation = Reservation.find_by_id_and_store_id params[:r_id].to_i,params[:store_id]
    order = nil
    product_ids = []
    status = 0
    if reservation && (reservation.status == Reservation::STATUS[:ACCEPTED] || reservation.status == Reservation::STATUS[:normal])
      time = reservation.res_time
      if params[:reserv_at]
        time = (params[:reserv_at].to_s + ":00").gsub(".","-")
      end
      if params[:types].to_i == 0     #确认预约
        user_id = params[:user_id].nil? ? cookies[:user_id] : params[:user_id]
        reservation.update_attributes(:status => Reservation::STATUS[:confirmed],:res_time => time)
        status = 1
        order = Order.make_record params[:c_id],params[:store_id],params[:car_num_id],params[:start],
          params[:end],params[:prods],params[:price],params[:station_id],user_id
      end
      if params[:types].to_i == 1     #取消预约
        reservation.update_attribute(:status, Reservation::STATUS[:cancel]) 
        status = 2
      end
    end
    render :json => {:status=>status,:order => order}
  end

  #投诉
  def complaint
    complaint = Complaint.mk_record params[:store_id],params[:order_id],params[:reason],params[:request],params[:types]
    render :json => {:status => (complaint.nil? ? 0 : 1)}
  end

  #返回订单
  def working_orders(store_id)
    orders = Order.working_orders store_id
    orders = combin_orders(orders)
    orders = order_by_status(orders)
    orders
  end
end
