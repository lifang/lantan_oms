class AddApplyContentToSvCard < ActiveRecord::Migration
  def change
    add_column :sv_cards, :apply_content, :string  #试用的产品
  end
end
