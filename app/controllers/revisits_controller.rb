#encoding: utf-8
class RevisitsController < ApplicationController    #客户回访
  before_filter :has_sign?, :get_title
  require 'will_paginate/array'
  def index
    @st_time = params[:search_revi_st_time].nil? ? (Time.now-3.days).strftime("%Y-%m-%d") : params[:search_revi_st_time]
    @ed_time = params[:search_revi_end_time].nil? ? (Time.now+3.days).strftime("%Y-%m-%d") : params[:search_revi_end_time]
    @car_num = params[:search_revi_carnum].nil? || params[:search_revi_carnum].strip=="" ? nil : params[:search_revi_carnum]
    @is_vip = params[:search_revi_is_vip].nil? ? nil : params[:search_revi_is_vip]
    @cus_property = params[:search_revi_cus_property].nil? ? nil : params[:search_revi_cus_property]
    @return_status = params[:search_revi_return_status].nil? ? nil : params[:search_revi_return_status]
    @srsc = params[:srsc]
    @count = params[:search_revi_count].nil? || params[:search_revi_count].strip=="" ? nil : params[:search_revi_count]
    @srsm = params[:srsm]
    @money = params[:search_revi_money].nil? || params[:search_revi_money].strip=="" ? nil : params[:search_revi_money]
    order = Order.get_order_customers(@store.id, @st_time, @ed_time, @car_num, @is_vip, @cus_property,
      @return_status, @count, @money)
    go = order.group_by{|o| o.is_visited}
    @unvisited = go[false].nil? ? 0 : go[false].group_by { |o|o.cu_id  }.keys.length
    @visited = go[true].nil? ? 0 : go[true].group_by { |o|o.cu_id  }.keys.length
    @orders = order.paginate(:page => params[:page], :per_page => 2)
  end

  def new
    order_id = params[:order_id]
    @order = Order.find_by_id(order_id)
    @order_prods = OrderProdRelation.find_by_sql(["select opr.pro_num, opr.price, opr.total_price, p.name
        from order_prod_relations opr
        inner join products p on opr.product_id=p.id
        where opr.order_id=?", @order.id])
    order_pay = OrderPayType.where(["order_id=?", @order.id]).map(&:pay_type)
    @op = []
    order_pay.each do |pay|
      @op << OrderPayType::PAY_TYPES_NAME[pay.to_i]
    end
    @car_num = CarNum.find_by_id(@order.car_num_id)
    @customer = Customer.find_by_id(@order.customer_id)
  end

  def create
    title = params[:revi_title]
    type = params[:revi_type].to_i
    con = params[:revi_content]
    answer = params[:revi_answer]
    is_comp = params[:is_complaint]
    order_id = params[:revi_order_id].to_i
    cus_id = params[:revi_customer_id].to_i
    Revisit.transaction do
      @status = 1
      begin
        order = Order.find_by_id(order_id)
        if is_comp && is_comp.to_i==1
          complaint = Complaint.create(:order_id => order.id, :reason => answer, :status => Complaint::STATUS[:UNTREATED],
            :customer_id => cus_id, :store_id => @store.id, :code => Complaint.make_code(@store.id))
        end
        revisit = Revisit.create(:customer_id => cus_id, :types => type,
          :title => title, :answer => answer, :content => con,
          :complaint_id => (complaint.nil? ? nil : complaint.id))
        RevisitOrderRelation.create(:order_id => order.id, :revisit_id => revisit.id)
        order.update_attributes(:is_visited => true) unless order.is_visited
        flash[:notice] = "添加回访成功!"
      rescue
        @status = 0
      end
    end
  end
  
  def get_title
    @title = "客户回访"
  end
end
