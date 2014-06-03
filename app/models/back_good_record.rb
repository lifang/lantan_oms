#encoding: utf-8
class BackGoodRecord < ActiveRecord::Base
  belongs_to :supplier
  belongs_to :product

  #获取门店的报损记录
  def self.get_back_records  store_id, supplier, type=nil, name=nil, code=nil, page
    sql = ["select bgr.product_num num, bgr.created_at,p.name pname, p.code pcode, c.name cname, s.name sname
      from back_good_records bgr inner join products p on bgr.product_id=p.id
      inner join categories c on p.category_id=c.id
      inner join suppliers s on bgr.supplier_id=s.id
      where bgr.store_id=?", store_id]
    unless supplier.to_i==0
      sql[0] += " and s.id=?"
      sql << supplier
    end
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
    sql[0] += " order by bgr.created_at desc"
    back_records = BackGoodRecord.paginate_by_sql(sql, :per_page => 3, :page => page)
    return back_records
  end
end
