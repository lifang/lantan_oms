#encoding: utf-8
require 'date'
class ProductOrder < ActiveRecord::Base
  has_many :prod_order_items
  has_many :prod_out_orders
  has_many  :prod_in_orders
  has_many  :prod_order_types
  has_many :products, :through => :prod_order_items
  belongs_to :supplier

  STATUS = {:no_pay => 0, :pay => 1, :cancel => 4}
  S_STATUS = { 0 => "未付款", 1 => "已付款", 4 => "已取消"}
  M_STATUS = {:no_send => 0, :send => 1, :received => 2, :save_in => 3, :returned => 4} #0未发货，1已发货，2已收货，3已入库，4已退货
  S_M_STATUS = { 0 => "未发货", 1 => "已发货", 2 => "已收货", 3 => "已入库", 4 => "已退货"}
  PAY_TYPES = {:CHARGE => 1, :BILL => 2, :CASH => 3, :DEBTS => 4}
  PAY_TYPE_NAME = {1 => "支付宝",2 => "支票", 3 => "现金", 4 => "挂账"}


  #获取订货记录
  def self.get_prod_order_records store_id, m_status=nil, status=nil, s_at=nil, e_at=nil, supplier=nil, page=nil
    sql = ["select po.*, s.name sname from product_orders po inner join suppliers s on po.supplier_id=s.id
      where po.store_id=?", store_id]
    unless  m_status.nil? || m_status.to_i == -1
      sql[0] += " and po.m_status=?"
      sql << m_status.to_i
    end
    unless  status.nil? || status.to_i == -1
      sql[0] += " and po.status=?"
      sql << status.to_i
    end
    unless s_at.nil? || s_at==""
      sql[0] += " and date_format(po.created_at,'%Y-%m-%d')>=?"
      sql << s_at
    end
    unless e_at.nil?  || e_at==""
      sql[0] += " and date_format(po.created_at,'%Y-%m-%d')<=?"
      sql << e_at
    end
    unless supplier.nil? || supplier.to_i==0
      sql[0] += " and s.id=?"
      sql << supplier.to_i
    end
    sql[0] += " order by po.created_at desc"
    prod_orders = ProductOrder.paginate_by_sql(sql, :per_page => 3, :page => page ||=1)
    return prod_orders
  end

  #生成订单号
  def self.material_order_code(store_id, time=nil)
    store = store_id.to_s
    if store_id < 10
      store =   "00" + store_id.to_s
    elsif store_id < 100
      store =    "0" + store_id.to_s
    end
    store + (time.nil? ? Time.now.strftime("%Y%m%d%H%M%S") : DateTime.parse(time).strftime("%Y%m%d%H%M%S"))
  end

end
