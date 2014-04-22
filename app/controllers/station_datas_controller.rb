#encoding: utf-8
class StationDatasController < ApplicationController  #系统设置-工位
  require 'will_paginate/array'
  before_filter :has_sign?, :get_title
  def index
    @s_name = params[:s_name]
    sql = ["select * from stations s where s.store_id=? and s.status!=?", @store.id, Station::STAT[:DELETED]]
    if @s_name.nil? == false && @s_name.strip != ""
      sql[0] += " and s.name like ?"
      sql << "%#{@s_name.strip.gsub(/[%_]/){|x| '\\' + x}}%"
    end
    sql[0] += " order by s.created_at desc"
    stations = Station.find_by_sql(sql)
    @total_s = stations.length
    @stations = stations.paginate(:page => params[:page] ||= 1, :per_page => 2) if stations.any?
    @s_service = StationServiceRelation.find_by_sql(["select ssr.station_id, p.name from station_service_relations
        ssr inner join products p on ssr.product_id=p.id where ssr.station_id in (?) and p.status=?",
        @stations.map(&:id), Product::STATUS[:NORMAL]]).group_by{|ss|ss.station_id} if @stations.any?
        
  end

  def edit
    @station = Station.find_by_id(params[:id].to_i)
    @station_services = @station.products.map(&:id)
    @categories = Category.where(["types = ? and store_id = ? ", Category::TYPES[:service], @store.id]).inject({}){|hash,c|hash[c.id]=c.name;hash};
    @services = @categories.empty? ? {}:Product.is_normal.where(:category_id => @categories.keys).group_by { |p| p.category_id }
    pack_serv = Product.is_normal.where(:category_id => Product::PACK[:PACK],:store_id=>@store.id)
    unless pack_serv.blank?
      @categories.merge!(Product::PACK_SERVIE)
      @services.merge!(Product::PACK[:PACK]=>pack_serv)
    end
    
    respond_to do |f|
      f.js
    end
  end
  
  def get_title
    @title = "工位设置"
  end
end
