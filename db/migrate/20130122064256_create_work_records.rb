class CreateWorkRecords < ActiveRecord::Migration
#  员工考勤
  def change
    create_table :work_records do |t|
      t.datetime :current_day   #年月日
      t.integer :attendance_num  #当月出勤
      t.integer :construct_num #施工次数
      t.integer :materials_used_num #使用工具
      t.integer :materials_consume_num  #材料损耗
      t.decimal :water_num,:precision=>"10,2",:default=>0     #水耗
      t.decimal :elec_num,:precision=>"10,2",:default=>0 #电消耗
      t.integer :complaint_num   #投诉次数
      t.integer :train_num  #培训次数
      t.integer :violation_num  #违规次数
      t.integer :reward_num   #奖励次数
      t.integer :staff_id
      t.decimal :gas_num,:precision=>"10,2",:default=>0
      t.datetime :created_at
      t.integer :store_id  #添加工作记录的所属门店
      t.integer :attend_types, :default=>0
    end

    add_index :work_records, :current_day
    add_index :work_records, :staff_id
    add_index :work_records, :created_at
  end
end
