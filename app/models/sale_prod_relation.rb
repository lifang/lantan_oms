#encoding: utf-8
class SaleProdRelation < ActiveRecord::Base
  belongs_to :sale
  belongs_to  :product
  def self.get_sale_by_product(prod, prod_mat_num, total, sale_hash, prod_arr)
    prod_arr.each{|p| p[:count] = p[:count]+1 if p[:id]==prod.id }
    product_ids = prod_arr.map{|p| p[:id]}
    unless product_ids.include?(prod.id)
      product = Hash.new
      product[:id] = prod.id
      product[:name] = prod.name
      product[:price] = prod.sale_price
      product[:count] = 1
      product[:num] = prod_mat_num if prod.is_service == false
      prod_arr << product
      total += product[:price]
    end

    #产品相关的活动
    prod.sale_prod_relations.each{|r|
      if r.sale and r.sale.status == Sale::STATUS[:RELEASE] and (r.sale.disc_time_types != Sale::DISC_TIME[:TIME] || (r.sale.disc_time_types == Sale::DISC_TIME[:TIME] and r.sale.ended_at > Time.now))
        s = sale_hash[r.sale_id] ? sale_hash[r.sale_id] : Hash.new
        s[:sale_id] = r.sale_id
        s[:sale_name] =r.sale.name
        if r.sale.disc_types == Sale::DISC_TYPES[:FEE]
          s[:price] = r.sale.discount
        elsif r.sale.disc_types == Sale::DISC_TYPES[:DIS]
          s[:price] = sale_hash[r.sale_id] ? (s[:price].to_i + (prod.sale_price * (10 - r.sale.discount) / 10)) : (prod.sale_price * (10 - r.sale.discount) / 10)
        end
        s[:selected] = 1
        s[:show_price] = 0.0#"-" + s[:price].to_s
        s[:disc_types] = r.sale.disc_types
        s[:discount] = r.sale.discount
        s[:sale_products] = []
        sale_prod_relations = SaleProdRelation.find_by_sql(["select spr.product_id, spr.prod_num, p.name
                    from sale_prod_relations spr inner join products p
                    on p.id = spr.product_id where spr.sale_id = ?", r.sale.id])
        sale_prod_relations.each { |spr|
          s[:sale_products] << {:product_id => spr.product_id, :prod_num => spr.prod_num, :name => spr.name}
        }
        #sale_arr << s
        #total -= s[:price] unless sale_hash[r.sale_id]
        sale_hash[r.sale_id] = s

      end
    } if prod.sale_prod_relations
    return [sale_hash, prod_arr, total]
  end
end
