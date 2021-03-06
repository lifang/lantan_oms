#encoding: utf-8
class Revisit < ActiveRecord::Base
  belongs_to :customer
  has_many :revisit_order_relations
  belongs_to :complaint

  TYPES = {:SHOPPING => 0, :COMPLAINT => 1, :OTHER => 3} #回访类别
  TYPES_NAME = {0 => "消费回访", 1 => "投诉回访", 2 => "其他"}

  #客户的回访记录
  def self.customer_revists(store_id, customer_id, pre_page, page)
    return Revisit.paginate_by_sql(["select r.id r_id, r.created_at, r.types, r.content, r.answer, r.title, o.code, o.id o_id
          from revisits r left join revisit_order_relations ror
          on ror.revisit_id = r.id left join orders o on o.id = ror.order_id where o.store_id=? and r.customer_id=?
          order by r.created_at desc",
        store_id, customer_id], :per_page => pre_page, :page => page)
  end
  
end
