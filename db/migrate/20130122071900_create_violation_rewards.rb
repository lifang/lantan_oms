class CreateViolationRewards < ActiveRecord::Migration
  def change
    create_table :violation_rewards do |t|
      t.integer :staff_id
      t.string :situation  #处罚/奖励原因
      t.boolean :status, :default => 0
      t.integer :process_types  #处置方式
      t.string :mark  #备注
      t.boolean :types   #处罚或者奖励
      t.integer :target_id  #相关订单
      t.float :score_num #按分值算
      t.float :salary_num #按金额算
      t.datetime :process_at
      t.integer :belong_types
      
      t.timestamps
    end

    add_index :violation_rewards, :staff_id
  end
end
