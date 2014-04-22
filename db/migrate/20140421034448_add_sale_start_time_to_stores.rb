#encoding: utf-8
class AddSaleStartTimeToStores < ActiveRecord::Migration
  def change
    add_column :stores, :sale_start_time, :string   #门店营业开始时间
    add_column :stores, :sale_end_time, :string   #门店营业结束时间
  end
end
