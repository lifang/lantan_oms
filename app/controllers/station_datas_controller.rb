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
    @category = Category.where(["types = ? and store_id = ? ", Category::TYPES[:service], @store.id]).inject({}){|hash,c|hash[c.id]=c.name;hash};
    @services = @category.empty? ? {}:Product.is_normal.where(:category_id => @category.keys).group_by { |p| p.category_id }
    pack_serv = Product.is_normal.where(:category_id => Product::PACK[:PACK],:store_id=>@store.id)
    unless pack_serv.blank?
      @category.merge!(Product::PACK_SERVIE)
      @services.merge!(Product::PACK[:PACK]=>pack_serv)
    end
    respond_to do |f|
      f.js
    end
  end

  def update
    name = params[:station_name]
    code = params[:station_code]
    has_controller = params[:station_has_controller].nil? || params[:station_has_controller].to_i==0 ? false : true
    coll_code = params[:station_collector_code]
    servs = params[:station_servs]
    Station.transaction do
      @station = Station.find_by_id(params[:id].to_i)
      begin
        @station.update_attributes({:name => name, :code => code, :is_has_controller => has_controller,
            :collector_code => coll_code})
        StationServiceRelation.delete_all(["station_id=?", @station.id])
        servs.each do |s|
          StationServiceRelation.create(:station_id => @station.id, :product_id => s.to_i)
        end if servs
        @has_services = @station.products.map(&:name)
        @status = 1
      rescue
        @status = 0
      end
    end
  end

  def new
    @category = Category.where(["types = ? and store_id = ? ", Category::TYPES[:service], @store.id]).inject({}){|hash,c|hash[c.id]=c.name;hash};
    @services = @category.empty? ? {}:Product.is_normal.where(:category_id => @category.keys).group_by { |p| p.category_id }
    pack_serv = Product.is_normal.where(:category_id => Product::PACK[:PACK],:store_id=>@store.id)
    unless pack_serv.blank?
      @category.merge!(Product::PACK_SERVIE)
      @services.merge!(Product::PACK[:PACK]=>pack_serv)
    end
    respond_to do |f|
      f.js
    end
  end

  def create
    name = params[:station_name]
    code = params[:station_code]
    has_controller = params[:station_has_controller].nil? || params[:station_has_controller].to_i==0 ? false : true
    coll_code = params[:station_collector_code]
    servs = params[:station_servs]
    Station.transaction do
      begin
        station = Station.create({:store_id => @store.id, :name => name, :code => code, :is_has_controller => has_controller,
            :collector_code => coll_code, :status => Station::STAT[:NORMAL]})
        servs.each do |s|
          StationServiceRelation.create(:station_id => station.id, :product_id => s.to_i)
        end if servs
        flash[:notice] = "创建成功!"
      rescue
        flash[:notice] = "创建失败!"
      end
    end
    redirect_to store_station_datas_path(@store)
  end

  def destroy
    Station.transaction do
      station = Station.find_by_id(params[:id].to_i)
      if station.update_column(:status, Station::STAT[:DELETED])
        flash[:notice] = "删除成功!"
      else
        flash[:notice] = "删除失败!"
      end
      redirect_to store_station_datas_path(@store)
    end
  end

  def name_valid
    type = params[:type].to_i
    name = params[:name]
    code = params[:code]
    status = 1
    if type == 0  #新建时验证
      obj = Station.where(["status!=? and store_id=? and (name=? or code=?)", Station::STAT[:DELETED], @store.id,
          name, code]).first
      if obj
        status = 0
      end
    elsif type == 1 #编辑时验证
      s_id = params[:station_id].to_i
      obj = Station.where(["id!=? and status!=? and store_id=? and (name=? or code=?)", s_id, Station::STAT[:DELETED],
          @store.id, name, code]).first
      if obj
        status = 0
      end
    end
    render :json => {:status => status}
  end

  def get_title
    @title = "工位设置"
  end
end
