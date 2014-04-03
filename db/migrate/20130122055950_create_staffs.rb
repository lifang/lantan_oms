class CreateStaffs < ActiveRecord::Migration
  #员工表
  def change
    create_table :staffs do |t|
      t.string :name
      t.integer :type_of_w   #职务
      t.integer :position    #岗位
      t.boolean :sex
      t.integer :level       #等级
      t.datetime :birthday
      t.string :id_card      #身份证
      t.string :hometown
      t.integer :education
      t.string :nation
      t.string :political
      t.string :phone
      t.string :address
      t.string :photo
      t.decimal :base_salary,:precision=>"20,2",:default=>0
      t.integer :deduct_at   #提成开始数量
      t.integer :deduct_end  #提成结束数量
      t.decimal :deduct_percent,:precision=>"20,2",:default=>0
      t.integer :status, :limit => 1  #员工状态
      t.integer :store_id
      t.string :encrypted_password
      t.string :username
      t.sting :salt
      t.boolaean :is_score_ge_salary, :default => false
      t.integer :working_stats    #在职状态 0试用 1正式
      t.integer :probation_salary   #试用薪资
      t.boolean :is_deduct,:default=>0 #是否提成
      t.integer :probation_days #试用期(天)
      t.string :validate_code
      t.integer :department_id
      t.integer :secure_fee, :default=>0
      t.integer :reward_fee, :default=>0
      
      t.timestamps
    end

    add_index :staffs, :name
    add_index :staffs, :status
    add_index :staffs, :store_id
    add_index :staffs, :level
    add_index :staffs, :type_of_w
    add_index :staffs, :position
    add_index :staffs, :username
  end
end
