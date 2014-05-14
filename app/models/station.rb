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
  validate :unique_code



  def self.make_data(store_id)
    return  "select c.num,w.station_id,o.front_staff_id,s.name,w.status,w.order_id from work_orders w inner join orders o on w.order_id=o.id inner join car_nums c on c.id=o.car_num_id
    inner join staffs s on s.id=o.front_staff_id where current_day='#{Time.now.strftime("%Y%m%d")}' and
    w.status in (#{WorkOrder::STAT[:SERVICING]},#{WorkOrder::STAT[:WAIT_PAY]}) and w.store_id=#{store_id}"
  end




  def self.arrange_time store_id, prod_ids, order = nil, res_time = nil
    #查询所有满足条件的工位
    stations = Station.includes(:wk_or_times).where(:store_id => store_id, :status => Station::STAT[:NORMAL])
    station_arr = []
    prod_ids = prod_ids.collect{|p| p.to_i }
    (stations || []).each do |station|
      if station.station_service_relations
        prods = station.station_service_relations.collect{|r| r.product_id }
        station_arr << station if (prods & prod_ids).sort == prod_ids.sort
      end
    end
    times_arr = []
    time_now = Time.now.strftime("%Y%m%d%H%M")
    times_arr << time_now
    station_id = 0

    #如果用户连续多次下单并且购买的服务可以在原工位上施工，则排在原来工位上。
    if order
      work_order = WorkOrder.joins(:order => :car_num).where(:car_nums => {:id => order.car_num_id},
        :work_orders => {:status => [WorkOrder::STAT[:WAIT], WorkOrder::STAT[:SERVICING]], :current_day => Time.now.strftime("%Y%m%d").to_i}).order("ended_at desc").first
      if work_order #5
        ended_at = work_order.ended_at
        last_order_ended_at = ended_at.strftime("%Y%m%d%H%M")
        times_arr << last_order_ended_at
        if station_arr.map(&:id).include?(work_order.station_id) #[1,3] 5
          station_id = work_order.station_id
        end
      end
    end
    if station_id == 0
      #按照工位的忙闲获取预计时间
      wkor_times = WkOrTime.where(:station_id => station_arr, :current_day => Time.now.strftime("%Y%m%d"))
      if wkor_times.blank?
        station_id = station_arr[0].try(:id) || 0
      else
        stations = Station.where(:id => wkor_times.map(&:station_id))
        no_order_stations = station_arr - stations #获得工位上没订单的工位
        if no_order_stations.present?
          station_id = no_order_stations[0].id
        else
          min_wkor_times = wkor_times.min{|a,b| a.current_times <=> b.current_times}
          min_ended_at = min_wkor_times.current_times
          times_arr << min_ended_at
          station_id = min_wkor_times.station_id
        end
      end
    end
    temp_time = times_arr.each{|t| Time.zone.parse(t)}.max
    time = (res_time && (temp_time < Time.zone.parse(res_time))) ? Time.zone.parse(res_time) : Time.zone.parse(temp_time)
    time_arr = [(time + Constant::W_MIN.minutes).strftime("%Y-%m-%d %H:%M"),
      (time + (Constant::W_MIN + Constant::STATION_MIN).minutes).strftime("%Y-%m-%d %H:%M"),station_id]
    #puts time_arr,"-----------------"
    time_arr
  end
end
