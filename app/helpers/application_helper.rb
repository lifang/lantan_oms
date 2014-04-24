#encoding: utf-8
module ApplicationHelper
  include RolesHelper

  def has_sign?
    store_id = params[:store_id]
    if cookies[:store_id].nil? || cookies[:staff_id].nil? || cookies[:staff_name].nil? || cookies[:store_name].nil?
      flash[:notice] = "请先登陆!"
      redirect_to "/"
    elsif store_id.to_i == 0 || cookies[:store_id] != Digest::MD5.hexdigest("#{store_id}")
      flash[:notice] = "请先登陆!"
      redirect_to "/"
    else
      @store = Store.find_by_id(params[:store_id].to_i)
    end
  end

  def is_hover(*controller_names)
    flag = false
    controller_names.each do |name|
      if request.url.include?(name)
        flag = true
        break
      end
    end
    return flag
  end
  
end
