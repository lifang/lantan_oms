#encoding: utf-8
class OrderProdManagesController < ApplicationController #库存管理中的订货记录
  before_filter :has_sign?, :get_title
  
  def index   #订货记录列表
    @s_at = params[:s_at]
    @e_at = params[:e_at]
    @supplier = params[:supplier]
    @suppliers = Supplier.where(["store_id=? and status=?", @store.id, Supplier::STATUS[:NORMAL]])
    @status = params[:status]
    @m_status = params[:m_status]
    page = params[:page] ||=1
    @prod_orders = ProductOrder.get_prod_order_records(@store.id, @m_status, @status, @s_at, @e_at, @supplier, page)
  end

  def new  #新建订货记录
    @mat_type = Category.where(["store_id=? and types=?", @store.id, Category::TYPES[:material]])
  end

  def create   #创建订货记录
    supp_name = params[:supplier_name]
    supp = Supplier.where(["name=? and store_id=? and status=?", supp_name, @store.id, Supplier::STATUS[:NORMAL]]).first
    status = 1
    if supp.nil?
      supp = Supplier.where(["cap_name=? and store_id=? and status=?", supp_name, @store.id, Supplier::STATUS[:NORMAL]]).first
      if supp.nil?
        status = 0
      end
    end
    if status == 1
      prods = params[:added_prod]
      pay_type = params[:pay_type].to_i
      begin
        ProductOrder.transaction do
          pro_order = ProductOrder.create(:code => ProductOrder.material_order_code(@store.id), :supplier_id => supp.id,
            :status => ProductOrder::STATUS[:no_pay], :staff_id => cookies[:staff_id],
            :store_id => @store.id, :status => pay_type==0 ? ProductOrder::STATUS[:no_pay] : ProductOrder::STATUS[:pay],
            :m_status => ProductOrder::M_STATUS[:no_send])
          price = 0
          prods.each do |k, v|
            prod = Product.find_by_id(k.to_i)
            price += prod.t_price.to_f*v.to_f
            ProdOrderItem.create(:product_order_id => pro_order.id, :product_id => prod.id, :product_num => v.to_f,
              :price => prod.t_price.to_f)
          end
          pro_order.update_attribute("price", price)
          if pay_type != 0
            ProdOrderType.create(:product_order_id => pro_order.id, :pay_types => pay_type, :price => price)
          end
          flash[:notice] = "订货成功!"
        end
      rescue
        flash[:notice] = "操作失败!"
      end
    else
      flash[:notice] = "未知的供应商!"
    end
    redirect_to "/stores/#{@store.id}/order_prod_manages"
  end
  
  def search_supplier
    name = params[:name].gsub(/[%_]/){|n|'\\' + n}
    @supplier = Supplier.where(["name like ? and store_id=? and status=?", "%#{name}%", @store.id,
        Supplier::STATUS[:NORMAL]])
    if @supplier.blank?
      @supplier = Supplier.where(["cap_name like ? and store_id=? and status=?", "%#{name}%", @store.id,Supplier::STATUS[:NORMAL]])
    end
  end

  def edit
    @types = params[:types].to_i
    @prod_order = ProductOrder.find_by_id(params[:id].to_i)
    if @types == 2
      @prod_order_items = ProdOrderItem.joins(:product).select("prod_order_items.*, products.name").where(["prod_order_items.product_order_id=?", @prod_order.id])
    end
  end

  def update
    types = params[:types].to_i
    @status = 1
    begin
      po = ProductOrder.find_by_id(params[:id].to_i)
      if types == 1
        remark = params[:remark]
        ProductOrder.transaction do
          po.update_attribute("remark", remark)
        end
      end
      flash[:notice] = "设置成功!"
    rescue
      @status = 0
    end
  end
  
  #退货和收货   1退货 2收货 3取消订单
  def confirm_and_back_goods
    types = params[:types].to_i
    @status = 1
    begin
      ProductOrder.transaction do
        po = ProductOrder.find_by_id(params[:po_id].to_i)
        if types == 1
          po.update_attribute("m_status", ProductOrder::M_STATUS[:returned])
        elsif types == 2
          po.update_attribute("m_status", ProductOrder::M_STATUS[:received])
        elsif types == 3
          po.update_attribute("status", ProductOrder::STATUS[:cancel])
        end
      end
      flash[:notice] = "设置成功!"
    rescue
      @status = 0
    end
    render "update"
  end

  #付款
  def order_prod_pay
    types = params[:types].to_i   #1 => "支付宝",2 => "支票", 3 => "现金", 4 => "挂账"
    @status = 1
    begin
      ProductOrder.transaction do
        po = ProductOrder.find_by_id(params[:po_id].to_i)
        pot = ProdOrderType.where(["product_order_id=?", po.id])
        if pot.any?
          flash[:notice] = "已付款!"
        else
          if types == 1
            ProdOrderType.create(:product_order_id => po.id, :pay_types => ProductOrder::PAY_TYPES[:CHARGE],
              :price => po.price)
          elsif types == 2
            ProdOrderType.create(:product_order_id => po.id, :pay_types => ProductOrder::PAY_TYPES[:BILL],
              :price => po.price)
          elsif types == 3
            ProdOrderType.create(:product_order_id => po.id, :pay_types => ProductOrder::PAY_TYPES[:CASH],
              :price => po.price)
          elsif types == 4
            ProdOrderType.create(:product_order_id => po.id, :pay_types => ProductOrder::PAY_TYPES[:DEBTS],
              :price => po.price)
          end
          po.update_attribute("status", ProductOrder::STATUS[:pay])
          flash[:notice] = "付款成功!"
        end
      end
    rescue
      @status = 0
    end
    render "update"
  end

  def search_prod
    prod_name = params[:prod_name]
    prod_type = params[:prod_type].to_i
    sql = ["select p.*, c.name cname from products p inner join categories c on p.category_id=c.id where
        p.store_id=? and p.status=? and p.types=?", @store.id, Product::STATUS[:NORMAL],Product::TYPES[:MATERIAL]]
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
  
  def get_title
    @title = "订货记录"
  end
  
end