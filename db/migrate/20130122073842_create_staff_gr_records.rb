class CreateStaffGrRecords < ActiveRecord::Migration
  #员工成长记录表
  def change
    create_table :staff_gr_records do |t|
      t.integer :staff_id
      t.integer :level        #等级
      t.integer :base_salary   #基本薪水
      t.integer :deduct_at   #提成开始数量
      t.integer :deduct_end  #提成结束数量
      t.float :deduct_percent
      t.integer :working_stats #在职状态 0试用 1正式
      t.timestamps
    end

    add_index :staff_gr_records, :staff_id
  end
end
