#encoding: utf-8
class SuppliersController < ApplicationController #库存管理中的供应商管理
  require 'will_paginate/array'
  before_filter :has_sign?, :get_title
  def index
    sql = ["select * from suppliers where store_id=? and status=?", @store.id, Supplier::STATUS[:NORMAL]]
    @type = params[:check_type]
    @name = params[:name]
    @cap_name = params[:cap_name]
    unless @type.nil? || @type.to_i==0
      sql[0] += " and check_type=?"
      sql << @type.to_i
    end
    unless @name.nil? || @name.strip==""
      sql[0] += " and name like ?"
      sql << "%#{@name.gsub(/[%_]/){|n|'\\' + n}}%"
    end
    unless @cap_name.nil? || @cap_name.strip==""
      sql[0] += " and cap_name=?"
      sql << @cap_name
    end
    sql[0] += " order by created_at desc"
    @suppliers = Supplier.paginate_by_sql(sql, :per_page => 2, :page => params[:page] ||=1)
  end

  def new
  end

  def create
    cap_name = params[:s_name].split(" ").join("").split("").compact.map{|n|
      n.pinyin[0][0] if n.pinyin[0]
    }
    hash = {
      :name => params[:s_name], :cap_name => cap_name.compact.join(""), :contact => params[:contact],
      :phone => params[:phone], :email => params[:email], :address => params[:address],
      :check_type => params[:check_type].to_i, :check_time => params[:check_time].to_i,
      :store_id => @store.id, :status => Supplier::STATUS[:NORMAL]
    }
    @status = 1
    @msg = ""
    begin
      Supplier.transaction do
        Supplier.create(hash)
        flash[:notice] = "新建成功!"
      end
    rescue
      @status = 0
      @msg = "新建失败!"
    end
  end
  
  def edit
    @status = 1
    @supplier = Supplier.find_by_id(params[:id].to_i)
    if @supplier.nil?
      @status = 0
    end
  end

  def update
    hash = {
      :name => params[:s_name], :cap_name => params[:cap_name], :contact => params[:contact], 
      :phone => params[:phone], :email => params[:email], :address => params[:address],
      :check_type => params[:check_type].to_i, :check_time => params[:check_time].to_i
    }
    @status = 1
    @msg = ""
    begin
      Supplier.transaction do
        supp = Supplier.find_by_id(params[:id].to_i)
        supp.update_attributes(hash)
        flash[:notice] = "编辑成功!"
      end
    rescue
      @status = 0
      @msg = "编辑失败!"
    end
  end
  
  def destroy
    @status = 1
    begin
      Supplier.transaction do
        supplier = Supplier.find_by_id(params[:id].to_i)
        supplier.update_attribute("status", Supplier::STATUS[:DELETED])
        flash[:notice] = "删除成功!"
      end
    rescue
      @status = 0
    end
  end

  #编辑或者新建供应商时的验证
  def supplier_valid
    supplier_id = params[:supplier_id].to_i
    name = params[:name].strip
    cap_name = params[:cap_name].strip
    phone = params[:phone].strip
    status = 1
    msg = ""
    if supplier_id == 0   #新建验证
      supp = Supplier.where(["status=? and store_id=? and name=?", Supplier::STATUS[:NORMAL],
          @store.id, name]).first
      if supp.nil?
        supp = Supplier.where(["status=? and store_id=? and cap_name=?", Supplier::STATUS[:NORMAL],
            @store.id, cap_name]).first
        if supp.nil?
          supp = Supplier.where(["status=? and store_id=? and phone=?", Supplier::STATUS[:NORMAL],
              @store.id, phone]).first
          if supp
            status = 0
            msg = "该手机号已存在!"
          end
        else
          status = 0
          msg = "该助记码已存在!"
        end
      else
        status = 0
        msg = "该名称已存在!"
      end
    else  #编辑验证
      supp = Supplier.where(["id!=? and status=? and store_id=? and name=?", supplier_id, Supplier::STATUS[:NORMAL],
          @store.id, name]).first
      if supp.nil?
        supp = Supplier.where(["id!=? and status=? and store_id=? and cap_name=?", supplier_id, Supplier::STATUS[:NORMAL],
            @store.id, cap_name]).first
        if supp.nil?
          supp = Supplier.where(["id!=? and status=? and store_id=? and phone=?", supplier_id, Supplier::STATUS[:NORMAL],
              @store.id, phone]).first
          if supp
            status = 0
            msg = "该手机号已存在!"
          end
        else
          status = 0
          msg = "该助记码已存在!"
        end
      else
        status = 0
        msg = "该名称已存在!"
      end
    end
    render :json => {:status => status, :msg => msg}
  end
  
  def get_title
    @title = "供应商管理"
  end
end