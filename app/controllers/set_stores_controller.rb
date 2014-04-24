#encoding: utf-8
class SetStoresController < ApplicationController   #系统设置-门店信息
  before_filter :has_sign?, :get_title
  require 'will_paginate/array'
  
  def index
    @store_city = City.find_by_id(@store.city_id) if @store.city_id
    @store_province = City.find_by_id(@store_city.parent_id) if @store_city
    @cities = City.where(["parent_id = ?", @store_city.parent_id]) if @store_city
    @province = City.where(["parent_id = ?", City::IS_PROVINCE])
  end

  def update
    Store.transaction do
      img = params[:store_img]
      attr_hash = {:name => params[:store_name], :address => params[:store_address], :phone => params[:store_phone],
        :contact => params[:store_contanct], :position => "#{params[:store_x_position]},#{params[:store_y_position]}",
        :city_id => params[:store_city_id].to_i, :limited_password => params[:store_lim_pwd],
        :status => params[:store_status].to_i,
        :cash_auth => params[:store_cash_auth].nil? || params[:store_cash_auth].to_i==0 ? 0 : 1,
        :sale_start_time => params[:store_status].to_i==Store::STATUS[:OPENED] ? params[:store_sale_stime] : nil,
        :sale_end_time => params[:store_status].to_i==Store::STATUS[:OPENED] ? params[:store_sale_etime] : nil,
        :auto_send => params[:store_auto_send].nil? || params[:store_auto_send].to_i==0 ? 0 : 1}
      if img.nil?
        if @store.update_attributes(attr_hash)
          flash[:notice] = "设置成功!"
        else
          flash[:notice] = "设置失败!"
        end
      else
        path, msg = Store.upload_img(img, @store.id)
        if path == ""
          flash[:notice] = msg
        else
          attr_hash.merge!({:img_url => path})
          if @store.update_attributes(attr_hash)
            flash[:notice] = "设置成功!"
          else
            flash[:notice] = "设置失败!"
          end
        end
      end
      redirect_to store_set_stores_path(@store)
    end
  end

  def search_cities
    province_id = params[:province_id].to_i
    @cities = City.where(["parent_id=?", province_id])
  end

  def get_title
    @title = "门店设置"
  end
end