#encoding: utf-8
class Order < ActiveRecord::Base
  has_many :order_prod_relations
  #  has_many :products, :through => :order_prod_relations
  has_many :order_pay_types
  has_many :work_orders
  belongs_to :car_num
  has_many :c_pcard_relations
  belongs_to :c_svc_relation
  belongs_to :customer
  belongs_to :sale
  has_many :revisit_order_relations
  has_many :o_pcard_relations
  has_many :complaints
  #  hash_many :tech_orders

  IS_VISITED = {:YES => 1, :NO => 0} #1 已访问  0 未访问
  STATUS = {:NORMAL => 0, :SERVICING => 1, :WAIT_PAYMENT => 2, :BEEN_PAYMENT => 3, :FINISHED => 4, :DELETED => 5, :INNORMAL => 6,
    :RETURN => 7, :COMMIT => 8, :PCARD_PAY => 9}
  STATUS_NAME = {0 => "等待中", 1 => "服务中", 2 => "等待付款", 3 => "已经付款", 4 => "免单", 5 => "已删除" , 6 => "未分配工位",
    7 =>"退单", 8 => "已确认，未付款(后台付款)", 9 => "套餐卡下单,等待付款"}
  #0 正常未进行  1 服务中  2 等待付款  3 已经付款  4 已结束  5已删除  6未分配工位 7 退单
  CASH =[STATUS[:NORMAL],STATUS[:SERVICING],STATUS[:WAIT_PAYMENT],STATUS[:COMMIT]]
  OVER_CASH = [STATUS[:BEEN_PAYMENT],STATUS[:FINISHED],STATUS[:RETURN]]
  PRINT_CASH = [STATUS[:BEEN_PAYMENT],STATUS[:FINISHED]]
  IS_FREE = {:YES=>1,:NO=>0} # 1免单 0 不免单
  TYPES = {:SERVICE => 0, :PRODUCT => 1} #0 服务  1 产品
  FREE_TYPE = {:ORDER_FREE =>"免单",:PCARD =>"套餐卡使用"}
  #是否满意
  IS_PLEASED = {:BAD => 0, :SOSO => 1, :GOOD => 2, :VERY_GOOD => 3}  #0 不满意  1 一般  2 好  3 很好
  IS_PLEASED_NAME = {0 => "不满意", 1 => "一般", 2 => "好", 3 => "很好"}
  VALID_STATUS = [STATUS[:BEEN_PAYMENT], STATUS[:FINISHED]]
  O_RETURN = {:WASTE => 0, :REUSE => 1}  #  退单时 0 为报损 1 为回库
  DIRECT = {0=>"报损", 1=>"回库"}
  IS_RETURN = {:YES=>1,:NO=>0} #0  成功交易  1退货
  RETURN = {0 =>"成功交易" , 1 => "已退单"} 


  #施工中的订单
  def self.working_orders store_id
    stations =Station.where("store_id=#{store_id} and status !=#{Station::STAT[:DELETED]}")
    sql = "select c.num,w.station_id,w.status,w.order_id from work_orders w inner join orders o on w.order_id=o.id inner join car_nums c on c.id=o.car_num_id
where w.current_day= '#{Time.now.strftime("%Y%m%d")}' and w.status in (#{WorkOrder::STAT[:SERVICING]},#{WorkOrder::STAT[:WAIT_PAY]},#{WorkOrder::STAT[:WAIT]}) and w.store_id=#{store_id}"
    work_orders = WorkOrder.find_by_sql(sql).group_by {|work_order| work_order.status}
    of_waiting = work_orders[WorkOrder::STAT[:WAIT]]
    orders_id = work_orders[WorkOrder::STAT[:SERVICING]].nil? ? [] : work_orders[WorkOrder::STAT[:SERVICING]].map(&:order_id)
    of_working = work_orders[WorkOrder::STAT[:SERVICING]].group_by { |working| working.station_id } if work_orders[WorkOrder::STAT[:SERVICING]]
    of_completed = work_orders[WorkOrder::STAT[:WAIT_PAY]]
    products = Product.find_by_sql("select id,name from products where status=#{Product::STATUS[:NORMAL]} and is_service = #{Product::PROD_TYPES[:SERVICE]} and store_id = #{store_id}")
    order_pro_rel = Product.joins(" p INNER JOIN order_prod_relations opr on p.id=opr.product_id").
      joins("inner join work_orders wo on wo.order_id=opr.order_id").select("p.id,p.name,opr.order_id,wo.station_id").
      where(["opr.order_id in (?)",orders_id]).group_by{|order_pro| order_pro.station_id}
    stations_order = []
    stations.each do |station|
       station_obj = station.attributes
       station_obj['of_working'] = of_working.present? && of_working[station.id].present? ?  of_working[station.id] : []
       station_obj['service'] = order_pro_rel.present? && order_pro_rel[station.id].present? ? order_pro_rel[station.id] : []
       stations_order << station_obj
    end if stations
    return [of_waiting,stations_order, of_completed,products]
  end
end
