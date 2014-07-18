#encoding: utf-8
class LoginsController < ApplicationController  #登陆
  layout :false
  def index
  end

  def validate
    user_name = params[:logins_name]
    user_pwd = params[:logins_pwd]
    if_save = params[:logins_save_user_info]
    @status = 1
    @msg = ""
    staff = Staff.find_by_username_and_status(user_name, Staff::STATUS[:normal])
    if staff.nil?
      @status = 0
      @msg = "用户不存在!"
    else
      if staff.has_password?(user_pwd) == false
        @status = 0
        @msg = "密码错误!"
      else
        @store = Store.find_by_id(staff.store_id) if staff.store_id
        if @store.nil? || @store.status != Store::STATUS[:OPENED]
          @status = 0
          @msg = "门店不存在或不在营业!"
        else
          cookies.delete(:store_id) if cookies[:store_id]
          cookies.delete(:store_name) if cookies[:store_name]
          cookies.delete(:staff_id) if cookies[:user_id]
          cookies.delete(:staff_name) if cookies[:user_name]
          if if_save.nil? || if_save.to_i == 0
            cookies[:store_id] = {:value => Digest::MD5.hexdigest("#{@store.id}"), :path => "/", :secure  => false}
            cookies[:staff_id] = {:value => staff.id, :path => "/", :secure  => false}
            cookies[:staff_name] = {:value => staff.name, :path => "/", :secure  => false}
            cookies[:store_name] = {:value => @store.name, :path => "/", :secure  => false}
          else
            cookies[:store_id] = {:value => Digest::MD5.hexdigest("#{@store.id}"), :path => "/", :secure  => false, :expires => 2.years.from_now.utc}
            cookies[:staff_id] = {:value => staff.id, :path => "/", :secure  => false, :expires => 2.years.from_now.utc}
            cookies[:staff_name] = {:value => staff.name, :path => "/", :secure  => false, :expires => 2.years.from_now.utc}
            cookies[:store_name] = {:value => @store.name, :path => "/", :secure  => false, :expires => 2.years.from_now.utc}
          end
        end
      end
    end
    respond_to do |f|
      f.js
    end
  end

  def logout
    cookies[:store_id] = nil
    cookies[:staff_id] = nil
    cookies[:staff_name] = nil
    cookies[:store_name] = nil
    cookies.delete(:store_id)
    cookies.delete(:staff_id)
    cookies.delete(:staff_name)
    cookies.delete(:store_name)
    redirect_to logins_path
  end

end
