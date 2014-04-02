class CreateStations < ActiveRecord::Migration
  #工位表
  def change
    create_table :stations do |t|
      t.integer :status  #工位状态
      t.integer :store_id
      t.string :name
      t.string :collector_code #采集器编号
      t.string :elec_switch #工位配电开关
      t.string :clean_m_fb #清洗机反馈
      t.string :gas_t_switch #气体流量开关
      t.string :gas_run_fb #空气机运行反馈
      t.string :gas_error_fb #空气机故障反馈
      t.string :system_error #系统报警
      t.string :is_using #工位有效占用
      t.string :day_hmi #工位日hmi复位
      t.string :month_hmi #工位月hmi复位
      t.string :once_gas_use #工位一次使用的气体数量
      t.string :once_water_use #工位一次使用的水数量
      t.float :gas_num
      t.boolean :is_has_controller
      t.integer :staff_level
      t.integer :staff_level1
      t.string :code    #添加采集器编号字段
      
      t.timestamps
    end

    add_index :stations, :status
    add_index :stations, :store_id
  end
end
