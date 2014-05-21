#encoding: utf-8
module MessageManagesHelper
  #获取某个用户的姓名，车牌，最近的消费时间和金额
  def get_customer_last_time_and_price customer_orders
    name = ""
    num = ""
    time = ""
    price = 0
    name = customer_orders.map(&:name).first
    num = customer_orders.inject([]){|arr,item|arr<<item.num;arr }.uniq.join(",")
    record = customer_orders.sort_by{|co|co.o_time}.last
    time = record.nil? || record.o_time.nil? ? "" : record.o_time.strftime("%y-%m-%d %H:%M")
    price = record.o_price.round(2) if record && record.o_price
    return [name, num, time, price]
  end

end