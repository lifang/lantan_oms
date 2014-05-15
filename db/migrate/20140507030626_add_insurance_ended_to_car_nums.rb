#encoding-utf8
class AddInsuranceEndedToCarNums < ActiveRecord::Migration
  def change
    add_column :car_nums, :insurance_ended, :datetime   #汽车保险截止时间
    add_column :car_nums, :last_inspection, :datetime   #汽车最近年检时间
    add_column :car_nums, :inspection_type, :integer   #汽车年检规则
    add_column :car_nums, :maint_distance, :integer, :default => 0   #汽车保养里程
  end
end
