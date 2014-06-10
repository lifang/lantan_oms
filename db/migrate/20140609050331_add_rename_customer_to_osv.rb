class AddRenameCustomerToOsv < ActiveRecord::Migration
  def change
     rename_column :o_pcard_relations, :c_pcard_relation_id, :customer_card_id
  end
end
