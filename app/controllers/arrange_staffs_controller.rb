#encoding: utf-8
class ArrangeStaffsController < ApplicationController #现场管理-分配技师
  before_filter :has_sign?, :get_title
  def index
    @stations = Station.where(["store_id=? and status!=?", @store.id, Station::STAT[:DELETED]])
    unless @stations.blank?
      normal_station_ids = @stations.inject([]){|arr,s|
        if s.status == Station::STAT[:NORMAL]
          arr << s.id
        end;
        arr
      }
      @station_staff_relations = StationStaffRelation.find_by_sql(["select ssr.station_id, s.id from
        station_staff_relations ssr inner join staffs s on ssr.staff_id=s.id where ssr.current_day=? and
        ssr.store_id=? and ssr.station_id in (?)", Time.now.strftime("%Y%m%d"),
          @store.id, normal_station_ids]).group_by{|s|s.station_id} if normal_station_ids.any?
      @staffs = Staff.select(["id, name"]).where(["store_id=? and status=? and type_of_w=?",
          @store.id, Staff::STATUS[:normal], Staff::S_COMPANY[:TECHNICIAN]])

    end
  end

  def create
    station_status = params[:station_status]
    station_staffs = params[:station_staffs]
    Station.transaction do
      begin
        station_status.each do |station_id, status|
          station = Station.find_by_id(station_id.to_i)
          station.update_attribute("status", status.to_i)
          if status.to_i == Station::STAT[:NORMAL]
            StationStaffRelation.delete_all(["station_id=? and current_day=?", station.id, Time.now.strftime("%Y%m%d")])
            station_staffs[station_id].values.each do |staff_id|
              StationStaffRelation.create({:station_id => station_id, :staff_id => staff_id.to_i,
                  :current_day => Time.now.strftime("%Y%m%d"), :store_id => @store.id})
            end if station_staffs && station_staffs[station_id]
          else
            StationStaffRelation.delete_all(["station_id=? and current_day=?", station.id, Time.now.strftime("%Y%m%d")])
          end
        end
        flash[:notice] = "分配成功!"
      rescue
        flash[:notice] = "分配失败!"
      end
      redirect_to store_arrange_staffs_path(@store)
    end
  end
  
  def get_title
    @title = "分配技师"
  end
end