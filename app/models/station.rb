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

  def self.station_service store_id
    stations = Station.where("store_id =? and status not in (?) ",store_id, [Station::STAT[:WRONG], Station::STAT[:DELETED]]).select("id, name")
    product_sta = Product.find_by_sql(["SELECT p.id product_id,p.name,ssr.station_id from  products p INNER JOIN station_service_relations ssr on p.id = ssr.product_id
        where p.is_service=#{Product::IS_SERVICE[:YES]} and ssr.station_id in (?) ",stations.map(&:id)]).group_by{|product| product.station_id}
    stations.each do |station|
      station['services'] = product_sta[station.id].nil? ? [] : product_sta[station.id]
    end
    return stations
  end



  def self.arrange_time store_id, prod_ids, order = nil, res_time = nil
    #查询所有满足条件的工位
    stations = Station.includes(:wk_or_times).where(:store_id => store_id, :status => Station::STAT[:NORMAL])
    station_arr = []
    station_prod_ids = []
    prod_ids = prod_ids.collect{|p| p.to_i }
    (stations || []).each do |station|
      if station.station_service_relations
        prods = station.station_service_relations.collect{|r| r.product_id }
        station_prod_ids << prods
        station_arr << station if (prods & prod_ids).sort == prod_ids.sort
      end
    end
    #    prod_ids = prod_ids.collect{|p| p.to_i }
    #    stations = Station.includes(:station_service_relations).where(:store_id => store_id, :status => Station::STAT[:NORMAL])
    #    (stations || []).each do |station|
    #      if station.station_service_relations
    #        prods = station.station_service_relations.collect{|r| r.product_id }
    #        station_prod_ids << prods
    #        station_arr << station if (prods & prod_ids).sort == prod_ids.sort
    #      end
    #    end
    if station_arr.present?
      station_flag = 1 #有对应工位对应
      station_staffs = StationStaffRelation.where(:station_id => station_arr)
      if station_staffs.blank?
        station_flag = 3
      end
    else
      if((station_prod_ids.flatten & prod_ids).sort == prod_ids.sort) && (!station_prod_ids.include?(prod_ids))
        station_flag = 2 #一个订单要使用多个工位
      else
        station_flag = 0 #没工位
      end
    end



    station_id = 0
    has_start_end_time = false
    #如果用户连续多次下单并且购买的服务可以在原工位上施工，则排在原来工位上。
    if order
      work_order = WorkOrder.joins(:order).where(:orders => {:car_num_id => order.car_num_id},
        :work_orders => {:status => WorkOrder::STAT[:SERVICING], :store_id => store_id,
          :current_day => Time.now.strftime("%Y%m%d").to_i}).order("ended_at desc").first
      if work_order #5
        if station_arr.map(&:id).include?(work_order.station_id) #[1,3] 5  # 看看同一辆车之前在的工位能不能施工现在下单的服务
          station_id = work_order.station_id
        end
      end
    end
    if station_id == 0
      #按照工位的忙闲获取预计时间
      # wkor_times = WkOrTime.where(:station_id => station_arr, :current_day => Time.now.strftime("%Y%m%d"))
      busy_stations = WorkOrder.where(:station_id => station_arr, :current_day => Time.now.strftime("%Y%m%d"),
        :store_id =>store_id, :status => [WorkOrder::STAT[:WAIT], WorkOrder::STAT[:SERVICING]]).map(&:station_id)

      availbale_stations = station_arr.map(&:id) - busy_stations

      if availbale_stations.present?
        if order && work_order #如果是同一辆车，需要排在不同的工位上的话，不置station_id和开始结束时间
          station_id = nil
        else
          #如果不是同一辆车，则排在不同的工位上，置station_id和开始结束时间
          station_id = availbale_stations[0] || 0
          has_start_end_time = true
        end
      else
        station_id = nil
      end
      # if busy_stations.blank?
      # if order && work_order #如果是同一辆车，需要排在不同的工位上的话，不置station_id和开始结束时间
      # station_id = nil
      # else
      # #如果不是同一辆车，则排在不同的工位上，置station_id和开始结束时间
      # station_id = station_arr[0].try(:id) || 0
      # has_start_end_time = true
      # end
      #
      # else
      # stations = Station.where(:id => busy_stations.map(&:station_id))
      # no_order_stations = station_arr - stations #获得工位上没订单的工位
      # if no_order_stations.present?
      # if order && work_order #如果是同一辆车，需要排在不同的工位上的话，不置station_id和开始结束时间
      # station_id = nil
      # else
      # #如果不是同一辆车，则排在不同的工位上，置station_id和开始结束时间
      # station_id = no_order_stations[0].id
      # has_start_end_time = true
      # end
      # else
      # #如果没有空闲工位的话， 则不置station_id和开始结束时间
      # station_id = nil
      # end
      # end
    end
    [station_id, station_flag, has_start_end_time]
  end


  #根据，订单，工位，门店id排空工位
  def self.create_work_order(station_id, store_id,order, hash, work_order_status, cost_time)
    started_at = Time.now
    ended_at = started_at + cost_time.minutes
    wo_time = WkOrTime.find_by_station_id_and_current_day station_id, Time.now.strftime("%Y%m%d").to_i if station_id
    if wo_time
      wo_time.update_attributes( :wait_num => wo_time.wait_num.to_i + 1)
    else
      WkOrTime.create(:current_times => ended_at.strftime("%Y%m%d%H%M"), :current_day => Time.now.strftime("%Y%m%d").to_i,
        :station_id => station_id, :worked_num => 1) if station_id and ended_at.present?
    end
    work_order = WorkOrder.create({
        :order_id => order.id,
        :current_day => Time.now.strftime("%Y%m%d"),
        :station_id => station_id || nil,
        :store_id => store_id,
        :status => (work_order_status ? WorkOrder::STAT[:SERVICING] : WorkOrder::STAT[:WAIT]),
        :started_at => work_order_status ? started_at : nil,
        :ended_at => work_order_status ? ended_at : nil,
        :cost_time => cost_time
      })

    hash ||= {}
    hash[:status] = (work_order.status == WorkOrder::STAT[:SERVICING]) ? Order::STATUS[:SERVICING] : Order::STATUS[:NORMAL]
    hash[:station_id] = station_id if station_id  #这个可能暂时没有值，一个完成后要更新
    station_staffs = StationStaffRelation.find_all_by_station_id_and_current_day station_id, Time.now.strftime("%Y%m%d").to_i if station_id
    if station_staffs
      hash[:cons_staff_id_1] = station_staffs[0].staff_id if station_staffs.size > 0
      hash[:cons_staff_id_2] = station_staffs[1].staff_id if station_staffs.size > 1
    end
    hash[:started_at] = work_order_status ? started_at : nil
    hash[:ended_at] = work_order_status ? ended_at : nil

    return hash
  end

  #  def self.arrange_time store_id, prod_ids, order = nil, res_time = nil
  #    #查询所有满足条件的工位
  #    stations = Station.includes(:wk_or_times).where(:store_id => store_id, :status => Station::STAT[:NORMAL])
  #    station_arr = []
  #    station_prod_ids = []
  #    prod_ids = prod_ids.collect{|p| p.to_i }
  #    (stations || []).each do |station|
  #      if station.station_service_relations
  #        prods = station.station_service_relations.collect{|r| r.product_id }
  #        station_prod_ids << prods
  #        station_arr << station if (prods & prod_ids).sort == prod_ids.sort
  #      end
  #    end
  #    p station_arr
  #    p station_prod_ids
  #    times_arr = []
  #    time_now = Time.now.strftime("%Y%m%d%H%M")
  #    times_arr << time_now
  #    station_id = 0
  #
  #    #如果用户连续多次下单并且购买的服务可以在原工位上施工，则排在原来工位上。
  #    if order
  #      work_order = WorkOrder.joins(:order => :car_num).where(:car_nums => {:id => order.car_num_id},
  #        :work_orders => {:status => [WorkOrder::STAT[:WAIT], WorkOrder::STAT[:SERVICING]], :current_day => Time.now.strftime("%Y%m%d").to_i}).order("ended_at desc").first
  #      if work_order #5
  #        ended_at = work_order.ended_at
  #        last_order_ended_at = ended_at.strftime("%Y%m%d%H%M")
  #        times_arr << last_order_ended_at
  #        if station_arr.map(&:id).include?(work_order.station_id) #[1,3] 5
  #          station_id = work_order.station_id
  #        end
  #      end
  #    end
  #    if station_id == 0
  #      #按照工位的忙闲获取预计时间
  #      wkor_times = WkOrTime.where(:station_id => station_arr, :current_day => Time.now.strftime("%Y%m%d"))
  #      if wkor_times.blank?
  #        station_id = station_arr[0].try(:id) || 0
  #      else
  #        stations = Station.where(:id => wkor_times.map(&:station_id))
  #        no_order_stations = station_arr - stations #获得工位上没订单的工位
  #        if no_order_stations.present?
  #          station_id = no_order_stations[0].id
  #        else
  #          min_wkor_times = wkor_times.min{|a,b| a.current_times <=> b.current_times}
  #          min_ended_at = min_wkor_times.current_times
  #          times_arr << min_ended_at
  #          station_id = min_wkor_times.station_id
  #        end
  #      end
  #    end
  #    temp_time = times_arr.each{|t| Time.zone.parse(t)}.max
  #    time = (res_time && (temp_time < Time.zone.parse(res_time))) ? Time.zone.parse(res_time) : Time.zone.parse(temp_time)
  #    time_arr = [(time + Constant::W_MIN.minutes).strftime("%Y-%m-%d %H:%M"),
  #      (time + (Constant::W_MIN + Constant::STATION_MIN).minutes).strftime("%Y-%m-%d %H:%M"),station_id]
  #    #puts time_arr,"-----------------"
  #    time_arr
  #  end
end
