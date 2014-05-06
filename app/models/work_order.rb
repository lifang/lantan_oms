#encoding: utf-8
class WorkOrder < ActiveRecord::Base
  belongs_to :station
  belongs_to :order
  belongs_to :store
  STATUS = {0=>"等待服务中",1=>"服务中",2=>"等待付款",3=>"已完成", 4 => "已取消", 5 => "已终止"}
  STAT = {:WAIT => 0,:SERVICING => 1,:WAIT_PAY => 2,:COMPLETE => 3, :CANCELED => 4, :END => 5}

#  def self.get_store_workorders(store_id)
#
#    datas = WorkOrder.find_by_sql(["select c.num,w.station_id,o.front_staff_id,w.status,w.order_id
#    from work_orders w inner join orders o on
#    w.order_id=o.id inner join car_nums c on c.id=o.car_num_id where current_day='#{Time.now.strftime("%Y%m%d")}' and
#    w.status in (#{WorkOrder::STAT[:SERVICING]},#{WorkOrder::STAT[:WAIT_PAY]},#{WorkOrder::STAT[:WAIT]}) and w.store_id=#{store_id}#"])
#  end

end
