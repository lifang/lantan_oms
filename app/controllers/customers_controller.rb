#encoding: utf-8
class CustomersController < ApplicationController
  before_filter :has_sign?
  before_filter :get_title, :only => [:index]
  before_filter :get_title2, :only => [:show]
  layout false, :only => [:print_orders]
  require 'will_paginate/array'

  def index
    @capitals = Capital.all
    @is_vip = params[:is_vip]
    @name = params[:name]
    @num = params[:num]
    @phone = params[:phone]
    if  @num && @num!=""
      sql = ["select c.id, c.name, c.mobilephone, c.is_vip, c.property from customers c
      inner join customer_num_relations cnr on c.id=cnr.customer_id
      inner join car_nums cn on cnr.car_num_id=cn.id
      where c.status=? and c.store_id=? and cn.num=?",  Customer::STATUS[:NOMAL], @store.id, @num]
    else
      sql = ["select c.id, c.name, c.mobilephone, c.is_vip, c.property from customers c
      where c.status=? and c.store_id=?", Customer::STATUS[:NOMAL], @store.id]
    end
    unless @is_vip.nil? || @is_vip.to_i == -1
      sql[0] += " and c.is_vip=?"
      sql << @is_vip.to_i
    end
    unless @name.nil? || @name==""
      sql[0] += " and c.name like ?"
      sql << "%#{@name.strip.gsub(/[%_]/){|x| '\\' + x}}%"
    end
    unless @phone.nil? || @phone==""
      sql[0] += " and c.mobilephone=?"
      sql << @phone
    end
    sql[0] += " order by c.created_at desc"
    customers = Customer.find_by_sql(sql)
    @customers = customers.paginate(:per_page => 2, :page => params[:page])
    @cus_car_nums = Customer.find_by_sql(["select c.id, cn.num, cm.name m_name, cb.name b_name from customers c
        inner join customer_num_relations cnr on c.id=cnr.customer_id
        inner join car_nums cn on cnr.car_num_id=cn.id
        left join car_models cm on cn.car_model_id=cm.id
        left join car_brands cb on cm.car_brand_id=cb.id
        where c.id in (?)", @customers.map(&:id)]).group_by{|c| c.id} if @customers.any?
    @orders_count = Order.where(["status in (?) and store_id=? and customer_id in (?)", Order::PRINT_CASH, @store.id,
        @customers.map(&:id)]).group_by{|o|o.customer_id} if @customers.any?
    @cus_count = customers.length
    @satisfy = Store.get_store_satisfy(@store.id)
    @complaints, @birth_notice = Customer.get_customer_tips(@store.id)
  end

  def show
    @type = params[:type]
    @customer = Customer.find_by_id(params[:id].to_i)
    @cus_nums = CustomerNumRelation.find_by_sql(["select cn.*, cm.id cmid, cm.name cmname, cb.name cbname
        from customer_num_relations cnr inner join car_nums cn on cnr.car_num_id=cn.id
        left join car_models cm on cn.car_model_id=cm.id
        left join car_brands cb on cm.car_brand_id=cb.id
        where cnr.customer_id=?", @customer.id]) if @type.nil?
    if @type.nil? || @type.to_i==1
      orders = Order.where(["status in (?) and customer_id=? and store_id=?", Order::OVER_CASH, @customer,
          @store.id])
      @order_count = orders.length
      @orders = orders.paginate(:page => params[:page] ||= 1, :per_page => 3)
      @order_pay_type = OrderPayType.order_pay_types(@orders)
      @pay_types = OrderPayType.pay_order_types(@orders.map(&:id))
    end
    @revisits = Revisit.customer_revists(@store.id, @customer.id, 1, params[:page] ||= 1) if @type.nil? || @type.to_i==2
    @complaints = Complaint.customer_complaints(@store.id, @customer.id, 1, params[:page] ||= 1)  if @type.nil? || @type.to_i==3
    
    respond_to do |f|
      f.html
      f.js
    end
  end

  def edit
    @customer = Customer.find_by_id(params[:id].to_i)
    @capitals = Capital.all
  end

  def update
    customer = Customer.find_by_id(params[:id].to_i)
    @status = 1
    @msg = ""
    name = params[:cus_name]
    phone = params[:cus_phone]
    car_item = params[:car_item]
    car_nums = []
    car_item.each do |k, v|
      car_nums << v["car_num"]
    end if car_item
    @status, @msg = Customer.customer_valid(car_nums, @store.id, 1, name, phone, customer.id)
    if @status==1
      Customer.transaction do
        sex = params[:cus_sex].to_i
        address = params[:cus_address].nil? || params[:cus_address]=="" ? nil : params[:cus_address]
        birthday = params[:cus_birthday].nil? || params[:cus_birthday]=="" ? nil : params[:cus_birthday]
        property = params[:cus_property].to_i
        group_name = property==0 || params[:cus_group_name].nil? || params[:cus_group_name]=="" ? nil : params[:cus_group_name]
        other_con = params[:cus_other_con].nil? || params[:cus_other_con]=="" ? nil : params[:cus_other_con]
        is_vip = params[:cus_is_vip].nil? || params[:cus_is_vip].to_i==0 ? 0 : 1
        allow_debts = params[:cus_allow_debts].to_i
        debts_money = allow_debts==0 || params[:cus_debts_money].nil? || params[:cus_debts_money]=="" ? nil : params[:cus_debts_money]
        check_type = allow_debts==0 || params[:cus_check_type].nil? ? nil : params[:cus_check_type].to_i
        check_time = allow_debts==0 ? nil : check_type.to_i==0 ? params[:debts_by_month].to_i : params[:debts_by_week].to_i
        begin
          customer.update_attributes({:name => name, :mobilephone => phone, :other_way => other_con, :sex => sex,
              :birthday => birthday, :address => address, :is_vip => is_vip, :status => Customer::STATUS[:NOMAL],
              :types => Customer::TYPES[:NORMAL], :username => name, :group_name => group_name, :property => property,
              :allowed_debts => allow_debts, :debts_money => debts_money, :check_type => check_type,
              :check_time => check_time, :store_id => @store.id})
          car_item.each do |k, v|
            car_num = CarNum.create(:num => v["car_num"], :car_model_id => v["car_model"].to_i, :buy_year => v["buy_year"],
              :distance => v["car_distance"].nil? || v["car_distance"]=="" ? nil : v["car_distance"],
              :insurance_ended => v["insurance_ended"].nil? || v["insurance_ended"]=="" ? nil : v["insurance_ended"],
              :last_inspection => v["last_inspection"].nil? ||  v["last_inspection"]=="" ? nil :  v["last_inspection"],
              :inspection_type => v["inspection_type"].nil? || v["inspection_type"]=="" ? nil : v["inspection_type"],
              :maint_distance => v["maint_distance"].nil? || v["maint_distance"]=="" ? nil : v["maint_distance"],
              :vin_code => v["vin_code"].nil? || v["vin_code"]=="" ? nil : v["vin_code"])
            CustomerNumRelation.create(:customer_id => customer.id, :car_num_id => car_num.id, :store_id => @store.id)
          end if car_item
          flash[:notice] = "编辑成功!"
        rescue
          @status = 0
          @msg = "编辑失败!"
        end
      end
    end
  end

  def create
    @status = 1
    @msg = ""
    name = params[:cus_name]
    phone = params[:cus_phone]
    car_item = params[:car_item]
    car_nums = []
    car_item.each do |k, v|
      car_nums << v["car_num"]
    end if car_item
    @status, @msg = Customer.customer_valid(car_nums, @store.id, 0, name, phone)
    if @status==1
      Customer.transaction do
        sex = params[:cus_sex].to_i
        address = params[:cus_address].nil? || params[:cus_address]=="" ? nil : params[:cus_address]
        birthday = params[:cus_birthday].nil? || params[:cus_birthday]=="" ? nil : params[:cus_birthday]
        property = params[:cus_property].to_i
        group_name = property==0 || params[:cus_group_name].nil? || params[:cus_group_name]=="" ? nil : params[:cus_group_name]
        other_con = params[:cus_other_con].nil? || params[:cus_other_con]=="" ? nil : params[:cus_other_con]
        is_vip = params[:cus_is_vip].nil? || params[:cus_is_vip].to_i==0 ? 0 : 1
        allow_debts = params[:cus_allow_debts].to_i
        debts_money = allow_debts==0 || params[:cus_debts_money].nil? || params[:cus_debts_money]=="" ? nil : params[:cus_debts_money]
        check_type = allow_debts==0 || params[:cus_check_type].nil? ? nil : params[:cus_check_type].to_i
        check_time = allow_debts==0 ? nil : check_type.to_i==0 ? params[:debts_by_month].to_i : params[:debts_by_week].to_i
        salt = Digest::MD5.hexdigest(Time.now.strftime("%Y%m%d%H%M%S"))
        begin
          customer = Customer.new(:name => name, :mobilephone => phone, :other_way => other_con, :sex => sex,
            :birthday => birthday, :address => address, :is_vip => is_vip, :status => Customer::STATUS[:NOMAL],
            :types => Customer::TYPES[:NORMAL], :username => name, :group_name => group_name, :property => property,
            :allowed_debts => allow_debts, :debts_money => debts_money, :check_type => check_type,
            :check_time => check_time, :salt => salt, :store_id => @store.id)
          customer.encrypted_password = Digest::MD5.hexdigest("888888#{salt}")
          customer.save
          car_item.each do |k, v|
            car_num = CarNum.create(:num => v["car_num"], :car_model_id => v["car_model"].to_i, :buy_year => v["buy_year"],
              :distance => v["car_distance"].nil? || v["car_distance"]=="" ? nil : v["car_distance"],
              :insurance_ended => v["insurance_ended"].nil? || v["insurance_ended"]=="" ? nil : v["insurance_ended"],
              :last_inspection => v["last_inspection"].nil? ||  v["last_inspection"]=="" ? nil :  v["last_inspection"],
              :inspection_type => v["inspection_type"].nil? || v["inspection_type"]=="" ? nil : v["inspection_type"],
              :maint_distance => v["maint_distance"].nil? || v["maint_distance"]=="" ? nil : v["maint_distance"],
              :vin_code => v["vin_code"].nil? || v["vin_code"]=="" ? nil : v["vin_code"])
            CustomerNumRelation.create(:customer_id => customer.id, :car_num_id => car_num.id, :store_id => @store.id)
          end if car_item
          flash[:notice] = "创建成功!"
        rescue
          @status = 0
          @msg = "创建失败!"
        end
      end
    end
  end

  def destroy
    Customer.transaction do
      cid = params[:id].to_i
      begin
        customer = Customer.find_by_id(cid)
        customer.update_attribute("status", Customer::STATUS[:DELETED])
        flash[:notice] = "删除成功!"
      rescue
        flash[:notice] = "删除失败!"
      end
    end
  end


  def add_car_get_datas #添加车辆 查找
    @type = params[:type].to_i
    id = params[:id].to_i
    if @type==0   #查车牌
      @brands = CarBrand.where(["capital_id = ?", id])
    elsif @type==1  #查车型
      @models = CarModel.where(["car_brand_id= ?", id])
    end
  end

  #添加车辆
  def add_car_item
    @buy_year = params[:buy_year]
    @car_model = params[:car_model]
    @car_model_text = params[:car_model_text]
    @car_brand_text = params[:car_brand_text]
    @car_distance = params[:car_distance]
    @last_inspection = params[:last_inspection]
    @inspection_type = params[:inspection_type]
    @insurance_ended = params[:insurance_ended]
    @maint_distance = params[:maint_distance]
    @car_num = params[:car_num]
    @vin_code = params[:vin_code]
    @index = params[:index].to_i
  end

  #打印消费记录
  def print_orders
    @orders = Order.find(params[:ids].split(","))
    @product_hash = {}
    @orders.each do |o|
      oprs = OrderProdRelation.where(["order_id=?", o.id])
      arr = []
      oprs.each do |opr|
        hash = {}
        if opr.prod_types==1
          prod = Product.find_by_id(opr.item_id)
          hash[:name] = prod.name
        else
          cc = CustomerCard.find_by_id(opr.item_id)
          card = cc.types==CustomerCard::TYPES[:PACKAGE] ? PackageCard.find_by_id(cc.card_id) : SvCard.find_by_id(cc.card_id)
          hash[:name] = card.name
        end
        hash[:num] = opr.pro_num
        hash[:price] = opr.price
        arr << hash
      end
      @product_hash[o.id] = arr
    end
    @order_pay_type = OrderPayType.order_pay_types(@orders)
  end

  #显示订单详情
  def show_order
    @order = Order.find_by_sql(["select o.*, s1.name front_name, s2.name cons_s_name1,s3.name cons_s_name2,
      s4.name return_name
      from orders o left join staffs s1 on s1.id = o.front_staff_id
      left join staffs s2 on s2.id = o.cons_staff_id_1
      left join staffs s3 on s2.id = o.cons_staff_id_2
      left join staffs s4 on s4.id = o.return_staff_id
      where o.id = ?", params[:order_id].to_i]).first
    oprs = OrderProdRelation.where(["order_id=?", @order.id])
    @products = []
    oprs.each do |opr|
      hash = {}
      if opr.prod_types==1
        prod = Product.find_by_id(opr.item_id)
        hash[:name] = prod.name
        hash[:num] = opr.pro_num
        hash[:price] = opr.price
        @products << hash
      else
        cc = CustomerCard.find_by_id(opr.item_id)
        card = cc.types==CustomerCard::TYPES[:PACKAGE] ? PackageCard.find_by_id(cc.card_id) : SvCard.find_by_id(cc.card_id)
        hash[:name] = card.name
        hash[:num] = opr.pro_num
        hash[:price] = opr.price
        @products << hash
      end
    end
  end

  #编辑车辆
  def edit_car
    cn_id = params[:carnum_id].to_i
    @car_num = CustomerNumRelation.find_by_sql(["select cn.*, cm.id cmid, cb.id cbid, cp.id cpid
        from car_nums cn left join car_models cm on cn.car_model_id=cm.id
        left join car_brands cb on cm.car_brand_id=cb.id
        left join capitals cp on cb.capital_id=cp.id
        where cn.id=?", cn_id]).first
    @brands = CarBrand.where(["capital_id=?", @car_num.cpid.to_i]) if @car_num && @car_num.cpid
    @models = CarModel.where(["car_brand_id=?", @car_num.cbid.to_i]) if @car_num && @car_num.cbid
    @capitals = Capital.all
  end

  #更新车辆
  def update_car
    car_num_id = params[:car_num_id].to_i
    car_num = params[:car_num]
    @status = 1
    @msg = ""
    car = CustomerNumRelation.joins(:car_num).where(["customer_num_relations.store_id=? and car_nums.id!=? and
        car_nums.num=?", @store.id, car_num_id, car_num,]).first
    if car
      @status = 0
      @msg = "车牌号#{car_num}已被注册!"
    else
      CarNum.transaction do
        hash = {:num => car_num, :car_model_id => params[:car_model].to_i, :buy_year => params[:buy_year],
          :distance => params[:distance].to_i, :insurance_ended => params[:insurance_ended],
          :last_inspection => params[:last_inspection], :inspection_type => params[:inspection_type].to_i,
          :maint_distance => params[:maint_distance], :vin_code => params[:vin_code]
        }
        begin
          car_num = CarNum.find_by_id(car_num_id)
          car_num.update_attributes(hash)
          flash[:notice] = "编辑成功!"
        rescue
          @status = 0
          @msg = "编辑失败!"
        end
      end
    end
  end

  #删除车辆
  def del_car
    car_num_id = params[:car_num_id]
    @status = 1
    CarNum.transaction do
      begin
        cnr = CustomerNumRelation.find_by_car_num_id(car_num_id)
        cnr.destroy
        cn = CarNum.find_by_id(car_num_id)
        cn.destroy
        flash[:notice] = "删除成功!"
      rescue
        @status = 0
      end
    end
  end
  
  #退单
  def return_order
    @order = Order.find_by_sql(["select o.*, s1.name front_name, s2.name cons_s_name1,s3.name cons_s_name2,
      s4.name return_name
      from orders o left join staffs s1 on s1.id = o.front_staff_id
      left join staffs s2 on s2.id = o.cons_staff_id_1
      left join staffs s3 on s2.id = o.cons_staff_id_2
      left join staffs s4 on s4.id = o.return_staff_id
      where o.id = ?", params[:order_id].to_i]).first
    oprs = OrderProdRelation.where(["order_id=?", @order.id])
    @products = []
    oprs.each do |opr|
      hash = {}
      if opr.prod_types==1
        prod = Product.find_by_id(opr.item_id)
        hash[:name] = prod.name
      else
        cc = CustomerCard.find_by_id(opr.item_id)
        card = cc.types==CustomerCard::TYPES[:PACKAGE] ? PackageCard.find_by_id(cc.card_id) : SvCard.find_by_id(cc.card_id)
        hash[:name] = card.name
      end
      hash[:num] = opr.pro_num
      hash[:price] = opr.price
      hash[:total_price] = opr.total_price
      @products << hash
    end
    order_pay = OrderPayType.where(["order_id=?", @order.id]).map(&:pay_type)
    @op = []
    order_pay.each do |pay|
      @op << OrderPayType::PAY_TYPES_NAME[pay.to_i]
    end
  end

  #创建退单
  def create_return_order
    @status = 1
    begin
      r_type = params[:return_type].to_i
      r_fee = params[:return_fee].to_f
      r_redirect = params[:return_redirect].to_i
      Order.transaction do
        order = Order.find_by_id(params[:return_order_id].to_i)
        oprs = OrderProdRelation.where(["order_id=?", order.id])
        oprs.each do |opr|
          if opr.prod_types == OrderProdRelation::PROD_TYPES[:CARD]
            cc = CustomerCard.find_by_id(opr.item_id)
            cc.update_attribute("status", CustomerCard::STATUS[:cancel])
          else
            prod = Product.find_by_id(opr.item_id)
            if r_redirect == 0    #报损
              ProductLoss.create(:product_id => prod.id, :loss_num => opr.pro_num.to_f.round(2),
                :staff_id => cookies[:staff_id], :store_id => @store.id)
            else  #回库
              prod.update_attribute("storage", (prod.storage.to_f + opr.pro_num.to_f).round(2))
            end
          end
        end
        order.update_attributes({:status => Order::STATUS[:RETURN], :return_types => Order::IS_RETURN[:NO],
            :return_direct => r_redirect, :return_staff_id => cookies[:staff_id]})
        ReturnOrder.create(:return_types => r_type, :return_direct => r_redirect, :return_fee => r_fee.round(2),
          :return_staff_id => cookies[:staff_id], :order_id => order.id, :store_id => @store.id)
        flash[:notice] = "退单成功!"
      end
    rescue
      @status = 0
    end
  end
  
  def get_title
    @title = "客户列表"
  end

  def get_title2
    @title = "客户详情"
  end

end
