#encoding: utf-8
class Sale < ActiveRecord::Base
  require 'mini_magick'
  has_many :sale_prod_relations
  belongs_to :store
  has_many :products, :through => :sale_prod_relations do
    def service
      where("is_service = true")
    end
  end
  
  STATUS={:UN_RELEASE =>0,:RELEASE =>1,:DESTROY =>2} #0 未发布 1 发布 2 删除
  STATUS_NAME={0=>"未发布",1=>"已发布",2=>"已删除"}
  DISC_TYPES = {:FEE =>1,:DIS =>0} #1 优惠金额  0 优惠折扣
  DISC_TYPES_NAME = {1 => "金额优惠", 0 => "折扣"}
  DISC_TIME = {:DAY =>1,:MONTH =>2,:YEAR =>3,:WEEK =>4,:TIME =>0} #1 每日 2 每月 3 每年 4 每周 0 时间段
  DISC_TIME_NAME ={1=>"本年度每天",2=>"本年度每月",3=>"本年度每年",4=>"本年度每周" }
  SUBSIDY = { :NO=>0,:YES=>1} # 0 不补贴 1 补贴
  TOTAL_DISC = [DISC_TIME[:DAY],DISC_TIME[:MONTH],DISC_TIME[:YEAR],DISC_TIME[:WEEK]]
  scope :valid, where("((ended_at > '#{Time.now}' and disc_time_types = #{DISC_TIME[:TIME]}) or disc_time_types!= #{DISC_TIME[:TIME]}) and is_subsidy = true and status=#{STATUS[:RELEASE]}")
  
  #下单时根据客户所选的产品返回所支持的活动(返回的活动只要支持该订单中某一个产品或者服务就加入进去)
  def self.get_customer_sales_by_products store_id, product_ids
    sales = Sale.where(["((ended_at>=? and disc_time_types=?) or disc_time_types!=?) and status=? and store_id=?", Time.now,
        DISC_TIME[:TIME], DISC_TIME[:TIME], STATUS[:RELEASE], store_id])
    result = sales.inject([]){|arr,sale|
      supported_prods = SaleProdRelation.where(["sale_id=?", sale.id])
      s_prods_ids = supported_prods.map(&:product_id)
      if s_prods_ids.any? && (s_prods_ids&product_ids).any? #如果该活动支持某个产品或服务
        hash = {:disc_types => sale.disc_types, :discount => sale.disc_types == DISC_TYPES[:FEE] ? nil : sale.discount,
          :price => sale.disc_types == DISC_TYPES[:FEE] ? sale.discount : nil, :sale_id => sale.id,
          :sale_name => sale.name, :selected => 0, :show_price => 0}
        prod_arr = []
        sale_products = SaleProdRelation.find_by_sql(["select spr.product_id, spr.prod_num, p.name
                    from sale_prod_relations spr inner join products p
                    on p.id = spr.product_id where spr.sale_id = ?", sale.id])
        sale_products.each do |sp|
          prod_hash = {:product_id => sp.product_id, :prod_num => sp.prod_num, :name => sp.name}
          prod_arr << prod_hash
        end
        hash[:products] = prod_arr
        arr << hash
      end;
      arr
    }
    return result
  end

end
