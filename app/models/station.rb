#encoding: utf-8
class Station < ActiveRecord::Base
  has_many :word_orders
  has_many :station_staff_relations
  has_many :staffs, :through => :station_staff_relations
  has_many :station_service_relations
  has_many :wk_or_times
  has_many :products, :through => :station_service_relations
  belongs_to :store
  has_many :equipment_infos
  STAT = {:WRONG =>0,:NORMAL =>2,:LACK =>1,:NO_SERVICE =>3, :DELETED => 4} #0 故障 1 缺少技师 2 正常 3 无服务 4删除
  STAT_NAME = {0=>"故障",1=>"缺少技师",2=>"正常",3=>"缺少服务项目"}
  VALID_STATUS = [STAT[:WRONG], STAT[:NORMAL], STAT[:LACK], STAT[:NO_SERVICE]]
  scope :can_show, where(:status => VALID_STATUS)
  IS_CONTROLLER = {:YES=>1,:NO=>0} #定义是否拥有工控机
  PerPage = 10
  validates :name, :presence => true



  def self.make_data(store_id)
    return  "select c.num,w.station_id,o.front_staff_id,s.name,w.status,w.order_id from work_orders w inner join orders o on w.order_id=o.id inner join car_nums c on c.id=o.car_num_id
    inner join staffs s on s.id=o.front_staff_id where current_day='#{Time.now.strftime("%Y%m%d")}' and
    w.status in (#{WorkOrder::STAT[:SERVICING]},#{WorkOrder::STAT[:WAIT_PAY]}) and w.store_id=#{store_id}"
  end

  def self.station_service store_id
    stations = Station.where("store_id =? and status not in (?) ",store_id, [Station::STAT[:WRONG], Station::STAT[:DELETED]]).select("id, name")
    product_sta = Product.find_by_sql(["SELECT p.id product_id,p.name,ssr.station_id from  products p INNER JOIN station_service_relations ssr on p.id = ssr.product_id
        where p.is_service=#{Product::IS_SERVICE[:YES]} and ssr.station_id in (?) ",stations.map(&:id)]).group_by{|product| product.station_id}
    stations.each do |station|
      station['services'] = product_sta[station.id].nil? ? [] : product_sta[station.id]
    end
    return stations
  end

  #给某个门店下的工位安排工单
  def self.arrange_work_orders store_id
    stations = Station.where(["status=? and store_id=?", STAT[:NORMAL], store_id]).order("created_at asc")
    stations.each do |s|
      #首先查看该工位当前在不在施工
      his_serving_wo = WorkOrder.where(["station_id=? and status=? and current_day=?", s.id, WorkOrder::STAT[:SERVICING],
        Time.now.strftime("%Y%m%d").to_i]).first
      if his_serving_wo.nil?  #如果该工位当前不在施工
        his_services = s.station_service_relations.map(&:product_id).collect{|p|p.to_i} #获取该工位可进行的服务
        #获取已排到该工位的正在等待的工单
        his_wait_wos = WorkOrder.where(["station_id=? and status=? and current_day=? and service_id in (?)", s.id,
            WorkOrder::STAT[:WAIT], Time.now.strftime("%Y%m%d").to_i, his_services]).order("created_at asc")
        if his_wait_wos.any?   #首先安排已排上该工位的工单施工(按时间先后顺序)
          his_wait_wos.each do |hww|
            #查看这个工单对应的订单当前在不在其他工位上施工
            other_serving_wos = WorkOrder.where(["station_id!=? and status=? and current_day=? and order_id=?",
              s.id, WorkOrder::STAT[:SERVICING], Time.now.strftime("%Y%m%d").to_i, hww.order_id])
            if other_serving_wos.blank? #如果这个工单对应的车辆正在其他工位施工，则跳过。否则安排该工单
              hww.update_attributes(:status => WorkOrder::STAT[:SERVICING], :started_at => Time.now,
                :ended_at => Time.now + hww.cost_time.to_i*60)
              current_order = hww.order
              current_order.update_attribute("status", Order::STATUS[:SERVICING]) if current_order.status==Order::STATUS[:NORMAL]
              break
            end
          end
        else   #如果没有排上该工位的工单 则查出最早的station_id为空的工单
          no_sid_wos = WorkOrder.where(["station_id is null and status=? and current_day=? and service_id in (?)",
            WorkOrder::STAT[:WAIT], Time.now.strftime("%Y%m%d").to_i, his_services]).order("created_at asc")
          no_sid_wos.each do |nsw|
            #查看这个工单对应的订单当前在不在其他工位上施工
            other_serving_wos = WorkOrder.where(["station_id!=? and status=? and current_day=? and order_id=?",
              s.id, WorkOrder::STAT[:SERVICING], Time.now.strftime("%Y%m%d").to_i, nsw.order_id])
             if other_serving_wos.blank? #如果这个工单对应的车辆正在其他工位施工，则跳过。否则安排该工单
               nsw.update_attributes(:station_id => s.id, :status => WorkOrder::STAT[:SERVICING], :started_at => Time.now,
                :ended_at => Time.now + nsw.cost_time.to_i*60)
              current_order = nsw.order
              current_order.update_attribute("status", Order::STATUS[:SERVICING]) if current_order.status==Order::STATUS[:NORMAL]
              break
             end
          end if no_sid_wos.any?
        end
      end
    end if stations.any?
  end

end
