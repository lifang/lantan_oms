#encoding: utf-8
class CustomerCard < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :sv_card
  STATUS = {:normal => 1, :cancel => 0} #0无效，1正常
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

  #下单时根据客户所选的产品返回所支持的储值卡(返回的储值卡必须是支持该订单中所有的产品和服务的)
  def self.get_customer_save_cards_by_products customer_id, product_ids
    p_cards = CustomerCard.find_by_sql(["select cc.*, sc.name, sc.apply_content from customer_cards cc inner join sv_cards sc
        on cc.card_id=sc.id where cc.customer_id=? and cc.types=? and cc.status=?", customer_id, TYPES[:STORED],
        STATUS[:normal]])
    result = p_cards.inject([]){|arr, card|
      supported_prods = card.apply_content.split(",").collect{|e|e.to_i}
      if supported_prods.any? && supported_prods & product_ids == product_ids
        hash = {:customer_save_id => card.id, :l_price => card.amt.to_f.round(2), :card_name => card.name}
        arr << hash
      end;
      arr
    }
    return result
  end

  #下单时根据客户所选的产品返回所支持的打折卡(返回的打折卡只要支持该订单中某一个产品或者服务就加入进去)
  def self.get_customer_discount_cards_by_products customer_id, product_ids
    s_cards = CustomerCard.find_by_sql(["select cc.*, sc.name, sc.apply_content
        from customer_cards cc inner join sv_cards sc
        on cc.card_id=sc.id where cc.customer_id=? and cc.types=? and cc.status=?", customer_id, TYPES[:DISCOUNT],
        STATUS[:normal]])
    result = s_cards.inject([]){|arr, card|
      supported_prods = card.apply_content.split(",").collect{|e|e.to_i}
      if supported_prods.any? && (supported_prods&product_ids).any?
        hash = {:customer_discount_id => card.id, :discount => card.discount.to_f.round(2), :card_name => card.name,
          :is_new => 0, :type => card.types, :show_price => 0}
        prods = []
        items = Product.where(["id in (?)", supported_prods])
        items.each do |i|
          prod_hash = {:pid => i.id, :pname => i.name, :pprice => i.sale_price.to_f.round(2), :selected => 0}
          prods << prod_hash
        end
        hash[:products] = prods
        arr << hash
      end;
      arr
    }
    return result
  end

  #下单时根据客户所选的产品返回所支持的套餐卡(返回的套餐只要支持该订单中某一个产品或者服务就加入进去)
  def self.get_customer_package_cards_by_products customer_id, product_ids, by_pcard_buy
    p_cards = CustomerCard.find_by_sql(["select cc.*, pc.id pcid, pc.name, pc.price
        from customer_cards cc inner join package_cards pc
        on cc.card_id=pc.id where cc.customer_id=? and cc.types=? and cc.status=?", customer_id, TYPES[:PACKAGE],
        STATUS[:normal]])
    result = p_cards.inject([]){|arr, card|
      flag = false
      ids = []  #该套餐卡支持的产品或服务的id
      card_content = card.package_content.split(",")  #447-0927mat1-2,448-0927mat2-2...
      card_content.each do |con|
        ids << con.split("-")[0].to_i
        if con.split("-")[2].to_i > 0
          flag = true
        end
      end if card_content.any?

      #如果该套餐卡没有用完并且支持某个产品或服务
      if flag && ids.any? && (ids&product_ids).any?
        hash = {:customer_package_id => card.id, :card_name => card.name, :is_new => 0, 
          :type => card.types, :show_price => 0}
        show_price = 0
        prods = []
        card_content.each do |con|
          p_id = con.split("-")[0].to_i
          left_count = con.split("-")[2].to_i
          product = Product.find_by_id(p_id)
          prod_hash = {:proid => product.id, :proname => product.name, :pro_left_count => left_count,
            :pprice => product.sale_price.to_f.round(2), :selected => 0, :select_num => 0}
          by_pcard_buy.each do |bpb_hash|
            if bpb_hash[:customer_pcard_id] == card.id && bpb_hash[:product_id] == product.id
              prod_hash[:selected] = 1
              prod_hash[:select_num] = bpb_hash[:num]
              show_price = show_price + (bpb_hash[:num].to_i * product.sale_price.to_f.round(2)).round(2)
              prod_hash[:pro_left_count] = (left_count - bpb_hash[:num]).to_i
            end
          end if by_pcard_buy.any?
          prods << prod_hash
        end
        hash[:show_price] = show_price * -1
        hash[:products] = prods
        arr << hash
      end;
      arr
    }
    return result
  end

end
