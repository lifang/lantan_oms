#encoding: utf-8
class Salary < ActiveRecord::Base
  belongs_to :staff

  def self.make_salary_list salaries    #生成员工工资清单
    xls_report = StringIO.new
    Spreadsheet.client_encoding = "UTF-8"
    book = Spreadsheet::Workbook.new
    sheet1 = book.create_worksheet :name => "员工工资清单"  #页卡
    sheet1.row(0).concat %w{员工姓名 部门 职务 基本工资 社保 工资合计 提成 补贴 奖励 扣款 加班 考核 所得税 实发工资}
    salaries.each_with_index do |s, index|
      sheet1.row(index + 1).concat ["#{s.sname}", "#{s.dname}", "#{s.pname}", "#{s.base_salary.to_f.round(2)}",
        "#{s.secure_fee.to_f.round(2)}", "#{s.total.to_f.round(2)}", "#{s.deduct_num.to_f.round(2)}",
        "#{s.reward_fee.to_f.round(2)}", "#{s.reward_num.to_f.round(2)}", "#{s.voilate_fee.to_f.round(2)}",
        "#{s.work_fee.to_f.round(2)}", "#{s.manage_fee.to_f.round(2)}", "#{s.tax_fee.to_f.round(2)}",
        "#{s.fact_fee.to_f.round(2)}"]
    end
    book.write xls_report
    xls_report.string
  end
end
