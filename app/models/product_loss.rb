class ProductLoss < ActiveRecord::Base
  belongs_to :staff
  belongs_to :product

  #获取门店的报损记录
  def self.get_prod_loss_records  store_id, type=nil, name=nil, code=nil, page=nil
    sql = ["select pl.loss_num num, p.name, p.code, p.t_price, p.base_price, s.name sname, c.name cname
      from product_losses pl inner join products p on pl.product_id=p.id
      inner join categories c on p.category_id=c.id
      left join staffs s on pl.staff_id=s.id
      where pl.store_id=?", store_id]
    unless type.to_i==0
      sql[0] += " and c.id=?"
      sql << type.to_i
    end
    unless name.nil? || name.strip==""
      sql[0] += " and p.name like ?"
      sql << "%#{name.gsub(/[%_]/){|n|'\\'+n}}%"
    end
    unless code.nil? || code.strip==""
      sql[0] += " and p.code=?"
      sql << code
    end
    sql[0] += " order by pl.created_at desc"
    prod_losses = ProductLoss.paginate_by_sql(sql, :per_page => 3, :page => page ||= 1)
    return prod_losses
  end
end