#encoding: utf-8
module ApplicationHelper
  require 'net/http'
  require "uri"
  require 'openssl'
  include RolesHelper
  include MessageManagesHelper
  
  MODEL_STATUS={:NORMAL=>0,:DELETED=>1,:INVALID=>2}
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

  #  订单中有哪些服务
  def combin_orders(orders)
    orders.map{|order|
      work_order = WorkOrder.find_by_order_id(order.order_id)
      service_name = Order.find_by_sql("select p.name p_name from orders o inner join order_prod_relations opr on opr.order_id=o.id inner join
            products p on p.id=opr.item_id where p.is_service=#{Product::IS_SERVICE[:YES]} and o.id = #{order.order_id}
            and opr.prod_types=#{OrderProdRelation::PROD_TYPES[:SERVICE]}").map(&:p_name).compact.uniq
      order[:wo_started_at] = (work_order && work_order.started_at && work_order.started_at.strftime("%Y-%m-%d %H:%M:%S")) || ""
      order[:wo_ended_at] = (work_order && work_order.ended_at && work_order.ended_at.strftime("%Y-%m-%d %H:%M:%S")) || ""
#      order[:car_num] = order.car_num.try(:num)
      order[:service_name] = service_name.join(",")
      order[:cost_time] = work_order.try(:cost_time)
      order[:station_id] = work_order.try(:station_id)
    }
    orders
  end


  #根据订单状态分组
  def order_by_status(orders)
    orders = orders.group_by{|order| order.status}
    #把免单的order放在已付款下面
    if orders[Order::STATUS[:FINISHED]].present?
      orders[Order::STATUS[:BEEN_PAYMENT]] ||= []
      orders[Order::STATUS[:BEEN_PAYMENT]] = (orders[Order::STATUS[:BEEN_PAYMENT]] << orders[Order::STATUS[:FINISHED]]).flatten
      orders.delete(Order::STATUS[:FINISHED])
    end
    orders
  end
  
  #保留金额的两位小数
  def limit_float(num)
    return (num*100).to_i/100.0
  end

  def create_get_http(url,route)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    if uri.port==443
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    request= Net::HTTP::Get.new(route)
    back_res =http.request(request)
    return JSON back_res.body
  end
end
