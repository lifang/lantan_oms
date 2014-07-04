class AddServiceIdToWorkOrders < ActiveRecord::Migration
  def change
    add_column :work_orders, :service_id, :integer
  end
end
