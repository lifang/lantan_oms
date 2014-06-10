#encoding: utf-8
class AttendancesController < ApplicationController #员工管理-出勤
  before_filter :has_sign?, :get_title

  def index
    @current_month = params[:current_month] ||= DateTime.now.strftime("%Y-%m")
    @name = params[:name]
    sql = ["select s.name, s.id, wr.attend_types, d1.name dname, d2.name pname from staffs s
      inner join work_records wr on s.id=wr.staff_id
       left join departments d1 on s.position=d1.id
      left join departments d2 on s.department_id=d2.id
      where s.store_id=? and s.status in (?) and date_format(wr.current_day,'%Y-%m')=?", @store.id, Staff::VALID_STATUS,
      @current_month]
    records = WorkRecord.find_by_sql(sql).group_by{|wr|wr.id}
    @result = []
    records.each do |k, v|
      hash = {}
      hash[:sid] = k
      attend, late, early, leave, absent, rest = 0, 0, 0, 0, 0, 0 #出勤，迟到，早退，请假，旷工，调休
      v.each do |att|
        hash[:sname] = att.name
        hash[:dname] = att.dname
        hash[:pname] = att.pname
        case att.attend_types
        when WorkRecord::ATTEND_TYPES[:ATTEND]
          attend += 1
        when WorkRecord::ATTEND_TYPES[:LATE]
          late += 1
        when WorkRecord::ATTEND_TYPES[:EARLY]
          early += 1
        when WorkRecord::ATTEND_TYPES[:LEAVE]
          leave += 1
        when WorkRecord::ATTEND_TYPES[:ABSENT]
          absent += 1
        when WorkRecord::ATTEND_TYPES[:REST]
          rest += 1
        end
      end
      hash[:attend] = attend
      hash[:late] = late
      hash[:early] = early
      hash[:leave] = leave
      hash[:absent] = absent
      hash[:rest] = rest
      @result << hash
    end

    respond_to do |f|
      f.html
      f.xls{
        send_data(
          WorkRecord.export_work_records(@result),
          :type => "text/excel;charset=utf-8; header=present",
          :filename => "#{@current_month}月份#{@store.name}员工出勤状况表.xls"
        )
      }
    end
  end
  
  def get_title
    @title = "出勤"
  end
end