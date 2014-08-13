#encoding: utf-8
class WelcomesController < ApplicationController  #主页
  before_filter :has_sign?
  layout :false
  def index
    @title = "欢迎"
        res = Reservation.find_by_sql(["select r.*,cn.num car_num,cm.name car_model_name,c.name customer_name,
        c.mobilephone, c.id cid, c.is_vip
        from reservations r inner join car_nums cn on r.car_num_id=cn.id
        inner join car_models cm on cn.car_model_id=cm.id
        inner join customer_num_relations cnr on cn.id=cnr.car_num_id
        inner join customers c on cnr.customer_id=c.id
        where r.store_id=? and r.status in (?) and r.created_at>=CURDATE()", 1, 
        [Reservation::STATUS[:normal], Reservation::STATUS[:ACCEPTED]]])
    p res
  end
  
end
