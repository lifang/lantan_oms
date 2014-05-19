class DeleteTableToCardsRelation < ActiveRecord::Migration
  def change
    drop_table :svcard_prod_relations
    drop_table :c_svc_relations
    drop_table :c_pcard_relations
  end
end
