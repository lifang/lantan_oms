class AddcoulmToSvCards < ActiveRecord::Migration
  def change
    add_column :sv_cards, :more_price, :decimal,{:precision=>"20,2",:default=>0}   #赠送金额
    add_column :sv_cards, :totle_price, :decimal,{:precision=>"20,2",:default=>0}   #卡的总金额
    add_column :sv_cards, :started_at, :datetime   #开始日期
    add_column :sv_cards, :ended_at, :datetime   #结束日期
    add_column :sv_cards, :date_types, :integer  #有效期类型
    add_column :sv_cards, :date_month, :integer  #有效期天数
    add_column :sv_cards, :create_staffid, :integer  #创建人
    add_index :sv_cards, :create_staffid
  end
end
