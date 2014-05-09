#encoding: utf-8
class Api::OrdersController < ApplicationController
  #  登录
  def login
    staff = Staff.find_by_username(params[:user_name])
    info = ""
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
      else
        cookies.delete(:user_id)
        cookies.delete(:user_name)
        cookies.delete(:user_roles)
        cookies.delete(:model_role)
        info = "抱歉，您没有访问权限"
      end
    end
    render :json => {:staff => staff, :info => info}.to_json
  end

  #首页,登录后的页面  施工现场
  def index_list
    status = 0
    begin
      reservations = Reservation.store_reservations params[:store_id]
      of_waiting,stations_order,of_completed,products = Order.working_orders params[:store_id]
      status = 1
    rescue
      status = 2
    end
    render :json => {:status => status,:of_waiting => of_waiting,:stations_order=> stations_order,:of_completed=> of_completed,
      :reservations => reservations,:products=>products}
  end

  #现场管理-订单详情
  def order_details
    order_details,order_pro,staff_store = Order.order_details params[:order_id]
    render :json => {:order_details=>order_details,:order_pro=>order_pro,:staff_store=>staff_store}
  end

  #用户界面（个人信息，订单列表）
  def user_and_order
    order_count,has_pay,orders_now = Staff.staff_and_order params[:staff_id]
    render :json => {:order_count => order_count,:has_pay=> has_pay,:orders_now => orders_now}
  end

  #删除预约
  def delete_reservation
    reservation = Reservation.find_by_id params[:reservation_id]
    status = 0
    notice = '删除失败！'
    if reservation && reservation.update_attributes(:status => Reservation::STATUS[:cancel])
      status = 1
      notice = '删除成功！'
    end
    render :json => {:status=> status,:notice=>notice}
  end
  #预约排单

  #查询产品（产品列表）
  def products_list
    status = 0
    product_name = params[:product_name].nil? || params[:product_name].strip == "" ? "%%" : "%"+ params[:product_name] +"%"
    if params[:store_id] && product_name
      status = 1
      product_list = Product.products_arr params[:store_id],product_name
    end
    render :json=>{:status => status,:product_list=>product_list }
  end

  #根据车牌号查询客户
  def search_car
    order = Order.search_by_car_num params[:store_id],params[:car_num], nil
    result = {:status => 1,:customer => order[0],:working => order[1], :old => order[2] }.to_json
    render :json => result
  end


  #下单
  def add
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
  end
end
