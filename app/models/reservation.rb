#encoding: utf-8
class Reservation < ActiveRecord::Base
  belongs_to :store
  belongs_to :customer
  belongs_to :car_num
  has_many :res_prod_relation, :dependent => :destroy

  STATUS = {:NORMAL => 0, :ACCEPTED => 1, :ARRANGED => 2,:REFUSED =>3} #0未处理 1接受 2已排单 3已拒绝

  #获取门店的预约信息
  def self.store_reservations store_id
    nor_array = []
    accpted_array = []
    status = 1
    msg = ""
    begin
      reses = Reservation.find_by_sql(["select r.*,cn.num carnum,cm.name car_model_name,c.name customer_name,
        c.mobilephone, c.id cid, c.is_vip
        from reservations r inner join car_nums cn on r.car_num_id=cn.id
        inner join car_models cm on cn.car_model_id=cm.id
        inner join customer_num_relations cnr on cn.id=cnr.car_num_id
        inner join customers c on cnr.customer_id=c.id
        where r.store_id=? and r.status in (?) and r.created_at>=CURDATE()", store_id, [STATUS[:NORMAL], STATUS[:ACCEPTED]]])
      reses.each do |res|
        hash = {:car_model_name => res.car_model_name, :created_at => res.created_at.strftime("%Y-%m-%d %H:%M"),
          :customer_id => res.cid, :id => res.id, :is_vip => res.is_vip, :mobilephone => res.mobilephone,
          :name => res.customer_name, :num => res.carnum, :res_time => res.res_time.nil? ? "" : res.res_time.strftime("%Y-%m-%d %H:%M"),
          :status => res.status}
        arr = []
        res_prods = Product.find_by_sql(["select p.* from res_prod_relations rpr inner join products p
            on rpr.product_id=p.id"])
        res_prods.each do |rp|
          hash2 = {:id => rp.id, :base_price => rp.base_price.to_f.round(2), :types => rp.types, :name => rp.name,
            :sale_price => rp.sale_price.to_f.round(2), :reservation_id =>res.id }
          arr << hash2
        end if res_prods.any?
        hash[:products] = arr
        if res.status == STATUS[:NORMAL]
          nor_array << hash
        else
          accpted_array << hash
        end
      end
    rescue
      status = 0
      msg = "数据错误!"
    end
    return [status, msg, nor_array, accpted_array]
  end

  #拒绝或者受理
  def self.is_accept reservation_id,store_id,types
    status = 1
    msg = ""
    obj = {}
    begin
      reservation = Reservation.find_by_id_and_store_id reservation_id,store_id
      Reservation.transaction do
        case types.to_i
        when 3  #拒绝
          reservation.update_attribute("status", types.to_i)
        when 2  #排单
          reservation.update_attribute("status", types.to_i)
        when 1  #受理
          reservation.update_attribute("status", types.to_i)
          status, msg, nor_array, accpted_array = store_reservations store_id
          obj[:reservations_normal] = nor_array
          obj[:reservations_accepted] = accpted_array
        end
      end
    rescue
      status = 0
      msg = "数据错误!"
    end
    return [status,msg,obj]
  end
end
