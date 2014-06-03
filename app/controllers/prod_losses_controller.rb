#encoding: utf-8
class ProdLossesController < ApplicationController #库存管理中的报损记录
  before_filter :has_sign?, :get_title

  def index
    @mat_type = Category.where(["store_id=? and types=?", @store.id, Category::TYPES[:material]])
    @type = params[:p_type].to_i
    @name = params[:p_name]
    @code = params[:p_code]
    page = params[:page].nil? ? 1 : params[:page]
    @pro_losses = ProductLoss.get_prod_loss_records(@store.id, @type, @name, @code, page)
  end

  def new
    @mat_type = Category.where(["store_id=? and types=?", @store.id, Category::TYPES[:material]])
    @staffs = Staff.where(["store_id=? and status=?", @store.id, Staff::STATUS[:normal]])
    sql = ["select p.*, c.name cname from products p inner join categories c
        on p.category_id=c.id where p.store_id=? and p.status=? and p.types=? and p.storage>0
        order by p.created_at desc",
      @store.id, Product::STATUS[:NORMAL], Product::TYPES[:MATERIAL]]
    @products = Product.find_by_sql(sql)
  end

  def create
    added_prod = params[:added_prod]
    staff = params[:out_staff].to_i
    msg = ""
    begin
      pids = added_prod.keys.uniq.collect{|e|e.to_i}
      products = Product.where(:id => pids)
      status = 1
      products.each do |p|
        loss_num = added_prod["#{p.id}"].to_f.round(2)
        if p.storage.to_f.round(2) < loss_num
          status = 0
          msg = "操作失败,#{p.name}的报损数量不得大于产品的库存量!"
          break
        end
      end
      if status == 1
        Product.transaction do
          products.each do |p|
            if added_prod["#{p.id}"]
              loss_num2 = added_prod["#{p.id}"].to_f.round(2)
              p.update_attribute("storage", p.storage.to_f.round(2)-loss_num2)
              ProductLoss.create!(:product_id => p.id, :loss_num => loss_num2, :staff_id => staff, :store_id => @store.id)
            end
          end
        end
        msg = "报损成功!"
      end
    rescue
      msg = "操作失败!"
    end
    flash[:notice] = msg
    redirect_to "/stores/#{@store.id}/prod_losses"
  end

  #报损时搜索产品
  def search_prods
    name = params[:search_prod_name]
    type = params[:search_prod_type].to_i
    sql = ["select p.*, c.name cname from products p inner join categories c
        on p.category_id=c.id where p.store_id=? and p.status=? and p.types=? and p.storage>0",
      @store.id, Product::STATUS[:NORMAL], Product::TYPES[:MATERIAL]]
    unless name.nil? || name.strip==""
      sql[0] += " and p.name like ?"
      sql << "%#{name.gsub(/[%_]/){|n|'\\' + n}}%"
    end
    unless type == 0
      sql[0] += " and c.id=?"
      sql << type
    end
    sql[0] += " order by p.created_at desc"
    @products = Product.find_by_sql(sql)
  end

  def get_title
    @title = "报损记录"
  end
end