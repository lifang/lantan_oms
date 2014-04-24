#encoding: utf-8
# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
Menu.create(:controller_name => "customers", :name => "客户管理")
Menu.create(:controller_name => "materials", :name => "库存管理")
Menu.create(:controller_name => "staffs", :name => "员工管理")
Menu.create(:controller_name => "datas", :name => "统计管理")
Menu.create(:controller_name => "stations", :name => "现场管理")
Menu.create(:controller_name => "sales", :name => "营销管理")
Menu.create(:controller_name => "base_datas", :name => "系统管理")
Menu.create(:controller_name => "pay_cash", :name => "收银管理")
Menu.create(:controller_name => "finances", :name => "财务管理")
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
