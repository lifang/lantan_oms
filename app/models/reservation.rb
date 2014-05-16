#encoding: utf-8
class Reservation < ActiveRecord::Base
  belongs_to :store
  belongs_to :customer
  belongs_to :car_num
  has_many :res_prod_relation, :dependent => :destroy

  STATUS = {:normal => 0, :cancel => 2, :confirmed => 1} #2取消，1下单了

  def self.store_reservations store_id
    self.find_by_sql(" select r.id, r.created_at,r.res_time,r.status,c.num,cu.name,cu.is_vip,cu.mobilephone,cu.other_way email,cm.name car_model_name,p.name pro_name
     from reservations r inner join car_nums c on c.id=r.car_num_id
      left join customer_num_relations cnr on cnr.car_num_id = c.id
      left join customers cu on cu.id=cnr.customer_id
			left join car_models cm on cm.id = c.car_model_id
			left join res_prod_relations rpr on rpr.reservation_id = r.id
			left join products p on p.id=rpr.product_id
      where r.store_id=#{store_id} and r.status != #{STATUS[:cancel]}  and r.created_at >= CURDATE() group by r.id order by r.status")
  end
end
