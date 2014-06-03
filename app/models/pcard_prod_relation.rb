#encoding: utf-8
class PcardProdRelation < ActiveRecord::Base
  belongs_to :package_card
  belongs_to :product

  def self.set_content pcard_id
    pcard_prod_relations = PcardProdRelation.find_all_by_package_card_id pcard_id
    content = nil
    content = pcard_prod_relations.collect{|r|
      s = ""
      if r.product
        s += r.product_id.to_s + "-" + r.product.name + "-" + r.product_num.to_s
      end
      s
    }.join(",") if pcard_prod_relations
    content
  end
  #购买已买过的套餐卡
  def self.reset_content content,p_card_id
    pcard_prod_relations = PcardProdRelation.find_all_by_package_card_id p_card_id
    pcard_prod_group =  pcard_prod_relations.group_by{|pcard_prod_relation|pcard_prod_relation.product_id }
    new_content = []
    cpr_content = content.split(",")
    (cpr_content ||[]).each do |pnn|
      prod_name_num = pnn.split("-")
      prod_id = prod_name_num[0]
      pcard_prod_group[prod_id]
      new_content << "#{prod_id.to_i}-#{prod_name_num[1]}-#{prod_name_num[2].to_i+pcard_prod_group[prod_id]}"
    end
    return new_content.join(",")
  end
end
