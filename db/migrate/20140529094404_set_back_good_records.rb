class SetBackGoodRecords < ActiveRecord::Migration
  def change
    change_column :back_good_records, :material_num, :decimal, :precision=>"20,2", :default => 0
    rename_column :back_good_records, :material_num, :product_num
    rename_column :back_good_records, :material_id, :product_id
  end
end
