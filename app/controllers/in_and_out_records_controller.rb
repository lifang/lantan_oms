#encoding: utf-8
class InAndOutRecordsController < ApplicationController #库存管理中的出库和入库记录
  before_filter :has_sign?, :get_title
  layout :false, :only => [:print_in_list]
  #出库记录列表
  def out_index
    @mat_type = Category.where(["store_id=? and types=?", @store.id, Category::TYPES[:material]])
    @type = params[:p_type].to_i
    @name = params[:p_name]
    @code = params[:p_code]
    sql = ["select por.product_num num,por.types types,por.created_at created_at,p.id pid,p.name pname,p.code pcode,
      p.t_price, p.base_price,s.name sname,c.name cname from prod_out_orders por inner join products p
      on por.product_id=p.id inner join staffs s on por.staff_id=s.id
      inner join categories c on p.category_id=c.id
      where por.store_id=?", @store.id]
    unless @type == 0
      sql[0] += " and c.id=?"
      sql << @type
    end
    unless  @name.nil? || @name.strip==""
      sql[0] += " and p.name like ?"
      sql << "%#{@name.gsub(/[%_]/){|n|'\\' + n}}%"
    end
    unless @code.nil? || @code.strip==""
      sql[0] += " and p.code=?"
      sql << @code
    end
    sql[0] += " order by por.created_at desc"
    @por = ProdOutOrder.paginate_by_sql(sql, :per_page => 2, :page => params[:page] ||= 1)
  end

  #新建出库
  def out_new
    @mat_type = Category.where(["store_id=? and types=?", @store.id, Category::TYPES[:material]])
    @out_types = ProdOutOrder::TYPES
    @staffs = Staff.where(["store_id=? and status=?", @store.id, Staff::STATUS[:normal]])
    sql = ["select p.*, c.name cname from products p inner join categories c
        on p.category_id=c.id where p.store_id=? and p.status=? and p.types=? order by p.created_at desc",
      @store.id, Product::STATUS[:NORMAL], Product::TYPES[:MATERIAL]]
    @products = Product.find_by_sql(sql)
  end

  #创建出库记录
  def out_create
    out_staff = params[:out_staff].to_i
    out_type = params[:out_type].to_i
    prods = params[:added_prod]
    db_prods = Product.where(["id in (?)", prods.keys.uniq])
    msg = ""
    status = 1
    db_prods.each do |dp|
      count = prods["#{dp.id}"].to_f
      if dp.storage.to_f < count
        status = 0
        msg += "产品#{dp.name}的库存量不足!"
      end
    end
    if status == 1
      ProdOutOrder.transaction do
        begin
          db_prods.each do |dp|
            count = prods["#{dp.id}"].to_f
            ProdOutOrder.create(:product_id => dp.id, :staff_id => out_staff, :product_num => count,
              :price => count * dp.base_price.to_f.round(2), :types => out_type, :store_id => @store.id) if count > 0
            dp.update_attribute("storage", dp.storage.to_f-count)
          end
          flash[:notice] = "操作成功!"
        rescue
          flash[:notice] = "操作失败!"
        end
      end
    else
      flash[:notice] = msg
    end
    redirect_to "/stores/#{@store.id}/in_and_out_records/out_index"
  end

  #入库记录列表
  def in_index
    @mat_type = Category.where(["store_id=? and types=?", @store.id, Category::TYPES[:material]])
    @type = params[:p_type].to_i
    @name = params[:p_name]
    @code = params[:p_code]
    sql = ["select pio.product_num nums,pio.created_at, p.code pcode, p.name, po.code pocode, c.name cname, s.name sname
      from prod_in_orders pio inner join products p on pio.product_id=p.id
      inner join product_orders po on pio.product_order_id=po.id
      inner join categories c on p.category_id=c.id
      inner join staffs s on pio.staff_id=s.id
      where po.store_id=?", @store.id]
    unless @type == 0
      sql[0] += " and c.id=?"
      sql << @type
    end
    unless  @name.nil? || @name.strip==""
      sql[0] += " and p.name like ?"
      sql << "%#{@name.gsub(/[%_]/){|n|'\\' + n}}%"
    end
    unless @code.nil? || @code.strip==""
      sql[0] += " and p.code=?"
      sql << @code
    end
    sql[0] += " order by pio.created_at desc"
    @por = ProdOutOrder.paginate_by_sql(sql, :per_page => 5, :page => params[:page] ||= 1)
  end

  #新建入库
  def in_new
    #已付款的 不是已入库的或者已退货的订单
    @prod_orders = ProductOrder.where(["store_id=? and status=? and m_status not in (?)", @store.id,
        ProductOrder::STATUS[:pay], [ProductOrder::M_STATUS[:save_in], ProductOrder::M_STATUS[:returned]]])
  end

  #创建入库记录
  def in_create
    prod = params[:prod]
    msg = ""
    status = 1
    begin
      prod_order = ProductOrder.find_by_id(params[:prod_order_id].to_i)
      prod_order_items = prod_order.prod_order_items.group_by{|pio|pio.product_id}
      prod_in_order = prod_order.prod_in_orders.group_by{|pio|pio.product_id}
      prod.each do |k, v|
        total_num = prod_order_items[k.to_i].nil? ? nil : prod_order_items[k.to_i].sum{|p|p.product_num}.to_f.round(2)
        has_num = prod_in_order[k.to_i].nil? ? 0 : prod_in_order[k.to_i].sum{|p|p.product_num}.to_f.round(2)
        if total_num.nil?
          status = 0
          msg = "数据错误!"
          break
        elsif v.to_f.round(2) > total_num || v.to_f.round(2) > (total_num-has_num).round(2)
          status = 0
          msg = "入库数量不得大于剩余的订货数量!"
          break
        end
      end
      if status == 1
        ProdInOrder.transaction do
          prod.each do |k, v|
            product = Product.find_by_id(k.to_i)
            ProdInOrder.create(:product_order_id => prod_order.id, :product_id => k.to_i, :product_num => v.to_f,
              :price => product.t_price, :staff_id => cookies[:staff_id]) if v != "" && v.to_f > 0
            product.update_attribute("storage", product.storage.to_f + v.to_f) if v != "" && v.to_f > 0
          end
          prod_order_items2 = prod_order.prod_order_items
          prod_in_order2 = ProdInOrder.where(["product_order_id=?", prod_order.id]).group_by{|pio|pio.product_id}
          flag = true   #判断是否完全入库，如果完全入库 则把该订单m_status设为已入库
          prod_order_items2.each do |poi|
            has_num2 = prod_in_order2[poi.product_id].nil? ? nil : prod_in_order2[poi.product_id].sum{|p|p.product_num}.to_f.round(2)
            if has_num2.nil? || has_num2 < poi.product_num.to_f.round(2)
              flag = false
              break
            end
          end
          if flag
            prod_order.update_attribute("m_status", ProductOrder::M_STATUS[:save_in])
          end
          msg = "入库成功!"
        end
      end
    rescue
      msg = "操作失败!"
    end
    flash[:notice] = msg
    redirect_to "/stores/#{@store.id}/in_and_out_records/in_index"
  end

  #打印入库清单
  def print_in_list
    @prod = params[:prod]
    prod_order_id = params[:prod_order_id].to_i
    @prod_order = ProductOrder.find_by_id(prod_order_id)
    pids = @prod.keys.collect{|e|e.to_i}.uniq
    @products = Product.where(:id => pids)

  end
  #出库时搜索产品
  def search_prods
    name = params[:search_prod_name]
    type = params[:search_prod_type].to_i
    sql = ["select p.*, c.name cname from products p inner join categories c
        on p.category_id=c.id where p.store_id=? and p.status=? and p.types=?",
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

  #入库时搜索产品记录
  def in_search_prods
    @order_prod = ProductOrder.find_by_id(params[:in_order_prod_id].to_i)
    @status = 1
    @msg = ""
    if @order_prod.nil?
      @status = 0
      @msg = "订单不存在!"
    elsif @order_prod.status != ProductOrder::STATUS[:pay] || @order_prod.m_status == ProductOrder::M_STATUS[:save_in] || @order_prod.m_status == ProductOrder::M_STATUS[:returned]
      @status = 0
      @msg = "订单状态异常!"
    else
      @prod_order_items = ProdOrderItem.find_by_sql(["select poi.product_num nums, p.id pid, p.name pname, p.t_price t_price,
          p.base_price base_price, c.name cname
          from prod_order_items poi inner join products p on poi.product_id=p.id
          inner join categories c on p.category_id=c.id
          where poi.product_order_id=?", @order_prod.id])
      @prod_order_in = @order_prod.prod_in_orders.group_by{|poi| poi.product_id}
    end
  end

  def get_title
    if request.url.include?("in_index")
      @title = "入库记录"
    else
      @title = "出库记录"
    end
  end

end