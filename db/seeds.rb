#encoding: utf-8
# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#菜单
num = 1 * 100000
Menu.create(:id => num+1,:controller_name => "customers",:name => "客户管理")
Menu.create(:id => num+2,:controller_name => "materials",:name => "库存管理")
Menu.create(:id => num+3,:controller_name => "staffs",:name => "员工管理")
Menu.create(:id => num+4,:controller_name => "datas",:name => "统计管理")
Menu.create(:id => num+5,:controller_name => "stations",:name => "现场管理")
Menu.create(:id => num+6,:controller_name => "sales",:name => "营销管理")
Menu.create(:id => num+7,:controller_name => "base_datas",:name => "基础数据")
Menu.create(:id => num+6,:controller_name => "pay_cash",:name => "收银管理")
Menu.create(:id => num+7,:controller_name => "finances",:name => "财务数据")
#角色
Role.create(:id => num+1,:name => "系统管理员")
Role.create(:id => num+2,:name => "老板")
Role.create(:id => num+3,:name => "店长")
Role.create(:id => num+4,:name => "员工")
#门店
Store.create(:id => num+1,:name => "杭州西湖路门店", :address => "杭州西湖路", :phone => "",
  :contact => "", :email => "", :position => "", :introduction => "", :img_url => "",
  :opened_at => Time.now, :account => 0, :created_at => Time.now, :updated_at => Time.now,
  :city_id => 1, :status => 1)
#系统管理员
staff = Staff.create(:name => "系统管理员", :type_of_w => 0, :position => 0, :sex => 1, :level => 2, :birthday => Time.now,
  :status => Staff::STATUS[:normal], :store_id => Store.first.id, :username => "admin", :password => "123456")
staff.encrypt_password
staff.save
StaffRoleRelation.create(:role_id => num+1, :staff_id => staff.id)


# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
