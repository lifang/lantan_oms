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

  #用户界面（个人信息，订单列表）
  def user_and_order
    order_count,has_pay,orders_now = Staff.staff_and_order params[:staff_id]
    render :json => {:order_count => order_count,:has_pay=> has_pay,:orders_now => orders_now}
  end
end
