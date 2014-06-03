#encoding: utf-8
class Reservation < ActiveRecord::Base
  belongs_to :store
  belongs_to :customer
  belongs_to :car_num
  has_many :res_prod_relation, :dependent => :destroy

  STATUS = {:normal => 0, :cancel => 2, :confirmed => 1,:REFUSAL =>3,:ACCEPTED =>4} #2取消，1下单了, 0未处理、3拒绝、4受理、下单、取消



  def self.store_reservations store_id
    #预约信息
    reservations = Reservation.find_by_sql("select r.id,DATE_FORMAT(r.created_at, '%Y-%m-%d %H:%i:%S') as new_created_at ,
      DATE_FORMAT(r.res_time, '%H:%i') as new_res_time ,r.status,c.num,cu.name,cu.is_vip,cu.mobilephone,
      cu.other_way email,cm.name car_model_name,cnr.customer_id
     from reservations r inner join car_nums c on c.id=r.car_num_id
      left join customer_num_relations cnr on cnr.car_num_id = c.id
      left join customers cu on cu.id=cnr.customer_id
			left join car_models cm on cm.id = c.car_model_id
      where r.store_id=#{store_id} and r.status in (#{STATUS[:normal]},#{STATUS[:ACCEPTED]})  and r.created_at >= CURDATE() order by r.status")
    reservation_id = reservations.map(&:id)
    reservations_status = reservations.group_by{|reservations_status| reservations_status.status }
    #预约产品
    product_res = Product.find_by_sql(["SELECT p.id,p.name,p.base_price,p.sale_price,p.types,p.is_service,rpr.reservation_id
      from products p inner join res_prod_relations rpr on p.id=rpr.product_id where p.status=1 and rpr.reservation_id in (?) ",reservation_id]).
      group_by{ |product| product.reservation_id }
    reservations_status[STATUS[:normal]].each do |reservation|
      reservation["products"] = product_res[reservation.id].nil? ? [] : product_res[reservation.id]
    end if reservations_status && reservations_status[STATUS[:normal]]

    reservations_status[STATUS[:ACCEPTED]].each do |reservation|
      reservation["products"] = product_res[reservation.id].nil? ? {} : product_res[reservation.id]
    end if reservations_status && reservations_status[STATUS[:ACCEPTED]]

    return [reservations_status[STATUS[:normal]],reservations_status[STATUS[:ACCEPTED]]]
  end

  #拒绝或者受理
  def self.is_accept reservation_id,store_id,types
    reservation = Reservation.find_by_id_and_store_id reservation_id,store_id
    status = 0
    notice = '预约不存在'
    if reservation
      if types.to_i == 4
        status = 1
        notice = '已受理'
      elsif types.to_i == 3
        status = 2
        notice = '已拒绝'
      else
        status = 3
        notice = '已取消'
      end
      reservation.update_attributes(:status => types)
    end
    return [status,notice]
  end
end
