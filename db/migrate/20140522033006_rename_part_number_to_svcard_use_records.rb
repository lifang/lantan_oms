class RenamePartNumberToSvcardUseRecords < ActiveRecord::Migration
  def change
    rename_column :svcard_use_records, :c_svc_relation_id, :customer_card_id
    add_index :svcard_use_records, :customer_card_id
  end
end
