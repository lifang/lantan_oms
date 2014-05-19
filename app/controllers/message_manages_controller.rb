#encoding: utf-8
class MessageManagesController < ApplicationController    #短信管理
  before_filter :has_sign?, :get_title
  require 'will_paginate/array'
  def index
    @st_time = params[:search_revi_st_time].nil? ? nil : params[:search_revi_st_time]
    @ed_time = params[:search_revi_end_time].nil? ? nil : params[:search_revi_end_time]
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
    @customers = order.group_by{|o|o.cu_id}
    #@message_temps = MessageTemp.where(["store_id=?", @store.id]).group_by{|mt|mt.type}
  end

  #新建短信模板
  def create
    MessageTemp.transaction do
      @status = 1
      type = params[:new_msg_temp_type].to_i
      content = params[:new_msg_temp_cont]
      begin
        msg_temp = MessageTemp.new(:types => type, :content => content, :store_id => @store.id)
        msg_temp.save
      rescue
        @status = 0
      end
    end
  end
  
  #发送短信
  def send_message
    cont = params[:send_msg_cont].strip
    c_ids = params[:send_msg_ids]
    @status = 1
    if c_ids == "" || cont==""
      @status = 0
    else
      cids = c_ids.split(",")
      SendMessage.transaction do
        msg_arr = []
        begin
          cids.each do |cid|
            customer = Customer.find_by_id(cid.to_i)
            if customer.mobilephone && customer.name
              c_name = "#{customer.name}先生/小姐"
              content = cont.strip.gsub(" ", "")
              SendMessage.create(:customer_id => customer.id, :types => SendMessage::TYPES[:OTHER],
                :content => content, :phone => customer.mobilephone,
                :send_at => Time.now, :status => MessageRecord::STATUS[:SENDED], :store_id => @store.id)
              msg_arr << {:content => content, :msid => "#{customer.id}", :mobile => customer.mobilephone}
            end
          end
          msg_hash = {:resend => 0, :list => msg_arr ,:size => msg_arr.length}
          jsondata = JSON msg_hash
          message_route = "/send_packet.do?Account=#{SendMessage::USERNAME}&Password=#{SendMessage::PASSWORD}&jsondata=#{jsondata}&Exno=0"
          create_get_http(SendMessage::MESSAGE_URL, message_route)
          flash[:notice] = "短信发送成功!"
        rescue
          @status = 0
        end
      end
    end
  end

  #根据选择的类型查询不同的信息模板
  def get_msg_temp_by_type
    @type = params[:type].to_i
    @msg_temps = MessageTemp.where(["types=? and store_id=?", @type, @store.id])
  end

  def get_title
    @title = "短信管理"
  end
end