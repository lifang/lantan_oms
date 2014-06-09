#encoding: utf-8
class MonthSalariesController < ApplicationController    #员工管理-工资表
  before_filter :has_sign?, :get_title
  require 'will_paginate/array'
  
  def index
    @current_month = params[:current_month] ||= DateTime.now.months_ago(1).strftime("%Y-%m")
    @name = params[:name]
    sql = ["select s.name sname, sl.*,d1.name dname, d2.name pname from staffs s
        inner join salaries sl on s.id=sl.staff_id
        left join departments d1 on s.position=d1.id
        left join departments d2 on s.department_id=d2.id
        where s.store_id=? and s.status in (?) and sl.current_month=?", @store.id, Staff::VALID_STATUS,
      @current_month.delete("-").to_i]
    unless @name.nil? || @name.strip==""
      sql[0] += " and s.name like ?"
      sql << "%#{@name.gsub(/[%_]/){|n|'\\' + n}}%"
    end
    sql[0] += " order by sl.created_at desc"
    sa = Salary.find_by_sql(sql)
    @total_sal = sa.inject(0){|total, d| total += d.fact_fee.to_f;total}
    @salaries = sa.paginate(:per_page => 10, :pafe => params[:page] ||= 1)
    respond_to do |f|
      f.html
      f.xls {
        send_data(
          Salary.make_salary_list(sa),
          :type => "text/excel;charset=utf-8; header=present",
          :filename => "#{@current_month}月份#{@store.name}员工工资表.xls"
        )
      }
    end
  end

  def get_title
    @title = "工资表"
  end
end