#encoding: utf-8
class StationsController < ApplicationController   #现场管理 -- 施工现场
  before_filter :has_sign?, :get_title
  require 'fileutils'

  #施工现场
  def index
    @stations = Station.where(["store_id=? and status!=?", @store.id, Station::STAT[:DELETED]])
    unless @stations.blank?
      normal_station_ids = @stations.inject([]){|arr,s|
        if s.status == Station::STAT[:NORMAL]
          arr << s.id
        end;
        arr
      }
      @station_staff_relations = StationStaffRelation.find_by_sql(["select ssr.station_id, s.name from
        station_staff_relations ssr inner join staffs s on ssr.staff_id=s.id where ssr.current_day=? and
        ssr.store_id=? and ssr.station_id in (?)", Time.now.strftime("%Y%m%d"),
          @store.id, normal_station_ids]).group_by{|s|s.station_id} if normal_station_ids.any?
      work_orders = WorkOrder.find_by_sql(["select wo.id, wo.station_id, wo.status, wo.order_id, wo.ended_at,
        wo.created_at, cn.num from work_orders wo inner join orders o on wo.order_id=o.id
        inner join car_nums cn on o.car_num_id=cn.id where wo.status in (?) and wo.current_day=? and wo.store_id=?",
          [WorkOrder::STAT[:WAIT],WorkOrder::STAT[:SERVICING], WorkOrder::STAT[:WAIT_PAY]], Time.now.strftime("%Y%m%d"),
          @store.id]).group_by{|wo|wo.status}
      @wait_wo = work_orders[WorkOrder::STAT[:WAIT]]
      @serving_wo = work_orders[WorkOrder::STAT[:SERVICING]].group_by{|wo|wo.station_id} if work_orders[WorkOrder::STAT[:SERVICING]]
      @finished_wo = work_orders[WorkOrder::STAT[:WAIT_PAY]]
    end
  end

  def show
    wo_id = params[:id].to_i
    @work_order = WorkOrder.find_by_sql(["select wo.id woid, o.id oid, o.code ocode, o.created_at start_time, s.name sname,
        staff1.name front_name, staff2.name con1_name, staff3.name con2_name, cn.num cnum
        from work_orders wo inner join orders o on wo.order_id=o.id
        inner join car_nums cn on o.car_num_id=cn.id
        left join stations s on wo.station_id=s.id
        left join staffs staff1 on o.front_staff_id=staff1.id
        left join staffs staff2 on o.cons_staff_id_1=staff2.id
        left join staffs staff3 on o.cons_staff_id_2=staff3.id
        where wo.id=?", wo_id]).first
    @opr = OrderProdRelation.joins(:product).select("order_prod_relations.*, products.name")
    .where(["order_prod_relations.order_id=?", @work_order.oid]).first if @work_order
  end

  
  def get_title
    @title = "施工现场"
  end
end
