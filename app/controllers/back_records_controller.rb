#encoding: utf-8
class BackRecordsController < ApplicationController #库存管理中的报损记录
  before_filter :has_sign?, :get_title

  def index
    @supplier = params[:supplier]
    @suppliers = Supplier.where(["store_id=? and status=?", @store.id, Supplier::STATUS[:NORMAL]])
    @mat_type = Category.where(["store_id=? and types=?", @store.id, Category::TYPES[:material]])
    @type = params[:p_type].to_i
    @name = params[:p_name]
    @code = params[:p_code]
    page = params[:page] ||=1
    @back_records = BackGoodRecord.get_back_records(@store.id, @supplier, @type, @name, @code, page)
    p @back_records
  end

  def new
    @mat_type = Category.where(["store_id=? and types=?", @store.id, Category::TYPES[:material]])
    sql = ["select p.*, c.name cname from products p inner join categories c
        on p.category_id=c.id where p.store_id=? and p.status=? and p.types=? and p.storage>0
        order by p.created_at desc",
      @store.id, Product::STATUS[:NORMAL], Product::TYPES[:MATERIAL]]
    @products = Product.find_by_sql(sql)
  end

  def create
    added_prod = params[:added_prod]
    supp_name = params[:supplier_name]
    msg = ""
    begin
      status = 1
      supp = Supplier.where(["name=? and store_id=? and status=?", supp_name, @store.id, Supplier::STATUS[:NORMAL]]).first
      if supp.nil?
        supp = Supplier.where(["cap_name=? and store_id=? and status=?", supp_name, @store.id, Supplier::STATUS[:NORMAL]]).first
        if supp.nil?
          status = 0
          msg = "未知的供应商!"
        end
      end
      if status == 1
        pids = added_prod.keys.collect{|e|e.to_i}
        products = Product.where(:id => pids)
        products.each do |p|
          has_num = added_prod["#{p.id}"].to_f.round(2)
          if has_num > p.storage.to_f.round(2)
            status = 0
            msg = "#{p.name}的退货数量大于库存量!"
            break
          end
        end
        if status == 1
          products.each do |p|
            p.update_attribute("storage", p.storage.to_f.round(2)-added_prod["#{p.id}"].to_f.round(2))
            BackGoodRecord.create(:product_id => p.id, :product_num => added_prod["#{p.id}"].to_f.round(2),
              :supplier_id => supp.id, :store_id => @store.id) if added_prod["#{p.id}"].to_f.round(2) > 0
          end
          msg = "操作成功!"
        end
      end
    rescue
      msg = "操作失败!"
    end
    flash[:notice] = msg
    redirect_to "/stores/#{@store.id}/back_records"
  end

  def search_prod
    prod_name = params[:prod_name]
    prod_type = params[:prod_type].to_i
    sql = ["select p.*, c.name cname from products p inner join categories c on p.category_id=c.id where
        p.store_id=? and p.status=? and p.types=?  and p.storage>0", @store.id,
      Product::STATUS[:NORMAL],Product::TYPES[:MATERIAL]]
    unless prod_name.nil? || prod_name.strip==""
      sql[0] += " and p.name like ?"
      sql << prod_name.gsub(/[%_]/){|n|'\\' + n}
    end
    unless prod_type==0
      sql[0] += " and c.id=?"
      sql << prod_type
    end
    @products = Product.find_by_sql(sql)
  end

  def search_supplier
    name = params[:name].gsub(/[%_]/){|n|'\\' + n}
    @supplier = Supplier.where(["name like ? and store_id=? and status=?", "%#{name}%", @store.id,
        Supplier::STATUS[:NORMAL]])
    if @supplier.blank?
      @supplier = Supplier.where(["cap_name like ? and store_id=? and status=?", "%#{name}%", @store.id,Supplier::STATUS[:NORMAL]])
    end
  end



  def get_title
    @title = "退货记录"
  end
end