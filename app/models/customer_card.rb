#encoding: utf-8
class CustomerCard < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :sv_card
  STATUS = {:normal => 1, :cancel => 2} #0取消，1正常
  TYPES = {:STORED => 1, :DISCOUNT => 2,:PACKAGE => 3} #储值卡：1；打折卡：2；套餐卡：3

  def self.product_has_cards  customer_pcards,prod,opcardre,prod_good,goods,customer_discounts
    #产品对应的套餐卡
    prod_good["id"] =  prod[1]
    prod_good["name"] =  goods.name
    prod_good["number"] = prod[2]
    pcard_prd = []
    customer_pcards.each do |cup|
      has_prod = 0
      customer_pcard ={}
      customer_pcard['id'] = cup.id
      pc_pr = cup.package_content.nil? ? [] : cup.package_content.split(",")
      pcard_pr =[]
      pc_pr.each do |pr|
        product = {}
        unuse_pr = pr.split("-")
        product['prduct_id'] = unuse_pr[0]
        product['prduct_name'] = unuse_pr[1]
        product['unuser_num'] = unuse_pr[2]
        if unuse_pr[0].to_i == prod[1]
          product['selected_num'] = opcardre[unuse_pr[0]]
          has_prod = 1
        else
          product['selected_num'] = 0
        end
        pcard_pr << product
      end if pc_pr.present?
      if has_prod
        pcard_prd << customer_pcard
      end
    end
    prod_good['package_card'] = pcard_prd
    #对应活动
    sale_hash, prod_arr = SaleProdRelation.get_sale_by_product(goods, nil, 0, {}, [])[0..1] if goods
    sale_arr = sale_hash.values if sale_hash
    prod_good['sale_arr'] = sale_arr
    #对应打折卡
    card_discount = []
    customer_discounts.each do |cus_d|
      discount = {}
      if cus_d.package_content.include?(prod[1])
        discount['id'] = cus_d.id
        discount['discount'] = cus_d.discount
        card_discount << discount
      end
    end
    prod_good["discount_card"] = card_discount
    return  prod_good
  end
end
