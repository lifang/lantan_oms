#encoding: utf-8
class WorkRecord < ActiveRecord::Base
  belongs_to :staff
  ATTEND_TYPES = {:ATTEND =>0,:LATE =>1,:EARLY =>2,:LEAVE =>3,:ABSENT =>4, :REST => 5}
  ATTEND_NAME = {0=>"出勤",1=>"迟到",2=>"早退",3=>"请假",4=>"旷工", 5=>"调休"}

  def self.export_work_records records_hash   #导出员工出勤状况数据
    xls_report = StringIO.new
    Spreadsheet.client_encoding = "UTF-8"
    book = Spreadsheet::Workbook.new
    sheet1 = book.create_worksheet :name => "员工工资清单"  #页卡
    sheet1.row(0).concat %w{员工姓名 部门 职务 出勤 迟到 早退 请假 旷工 调休}
    records_hash.each_with_index do |s, index|
      sheet1.row(index + 1).concat ["#{s[:sname]}", "#{s[:dname]}", "#{s[:pname]}", "#{s[:attend]}",
        "#{s[:late]}", "#{s[:early]}", "#{s[:leave]}", "#{s[:absent]}", "#{s[:rest]}"]
    end
    book.write xls_report
    xls_report.string
  end
end
