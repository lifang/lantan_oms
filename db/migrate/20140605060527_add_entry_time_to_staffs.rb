class AddEntryTimeToStaffs < ActiveRecord::Migration
  def change
    add_column :staffs, :entry_time, :datetime    #入职时间
    add_column :staffs, :labor_contract, :string  #劳动合同
    add_column :staffs, :remark, :string  #备注
    add_column :staffs, :w_days_monthly, :integer #每月工作日
  end
end
