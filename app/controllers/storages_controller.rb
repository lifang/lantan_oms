#encoding: utf-8
class StoragesController < ApplicationController #库存管理中的库存列表和出库记录
  #    require 'barby'
  #    require 'barby/barcode/ean_13'
  #    require 'barby/outputter/custom_rmagick_outputter'
  #    require 'barby/outputter/rmagick_outputter'
  before_filter :has_sign?, :get_title
  layout :false, :only => [:print_all_prods]
  def index
    @mat_type = Category.where(["store_id=? and types=?", @store.id, Category::TYPES[:material]])
    @p_type = params[:p_type]
    @p_name = params[:p_name]
    @p_code = params[:p_code]
    sql = ["select p.*, c.name cname from products p inner join categories c
        on p.category_id=c.id where p.store_id=? and p.status=? and p.types=?", @store.id, Product::STATUS[:NORMAL],
      Product::TYPES[:MATERIAL]]
    unless @p_type.nil? || @p_type.to_i==0
      sql[0] += " and c.id=?"
      sql << @p_type.to_i
    end
    unless @p_name.nil? || @p_name.strip==""
      sql[0] += " and p.name like ?"
      sql << "%#{@p_name.strip.gsub(/[%_]/){|x| '\\' + x}}%"
    end
    unless @p_code.nil? || @p_code.strip==""
      sql[0] += " and p.code=?"
      sql << @p_code
    end
    sql[0] += " order by p.created_at desc"
    @materials = Product.paginate_by_sql(sql, :per_page => 3, :page => params[:page])
  end

  def new
    @mat_type = Category.where(["store_id=? and types=?", @store.id, Category::TYPES[:material]])
    @revi_time = Product::REVIST_TIME
  end

  def create
    img = params[:p_image]
    is_shelves = params[:is_shelves].nil? || params[:is_shelves].to_i==0 ? false : true
    auto_revi = params[:auto_revist].nil? ? false : true
    is_added = params[:is_added].nil? ? false : true
    hash = {
      :name => params[:name], :code => params[:code].nil? || params[:code]=="" ? "123456" : params[:code],
      :base_price => params[:base_price], :sale_price => params[:sale_price], :t_price => params[:t_price],
      :description => params[:description], :introduction => params[:introduction], :types => Product::TYPES[:MATERIAL],
      :service_code => Product.make_service_code(4,"product", "service_code"), :status => Product::STATUS[:NORMAL],
      :is_shelves => is_shelves, :is_service => Product::IS_SERVICE[:NO], :store_id => @store.id,
      :standard => params[:standard], :unit => params[:unit], :is_auto_revist => auto_revi,
      :auto_time => auto_revi ? params[:revist_time].to_i : nil, :revist_content => auto_revi ? params[:revist_cont] : nil,
      :prod_point => is_shelves ? params[:p_point].to_i : nil, :category_id => params[:types].to_i,
      :is_added => is_added,
      :deduct_percent => is_shelves ? (params[:xs_t_type].to_i==2 ? params[:xs_t].to_f*params[:sale_price].to_f/100 : nil) : nil,
      :deduct_price => is_shelves ? (params[:xs_t_type].to_i==1 ? params[:xs_t].to_f : nil) : nil,
      :techin_percent => is_shelves && is_added ? (params[:js_t_type].to_i==2 ? params[:js_t].to_f*params[:sale_price].to_f/100 : nil) : nil,
      :techin_price => is_shelves && is_added ? (params[:js_t_type].to_i==1 ? params[:js_t].to_f : nil) : nil,
      :show_on_ipad => params[:show_on_pad].nil? || params[:show_on_pad].to_i==0 ? false : true,
      :cost_time => params[:cost_time].nil? ? nil : params[:cost_time].to_i
    }
    if img && img.size > Product::MAX_SIZE
      flash[:notice] = "新建失败,产品图片尺寸最大不得超过5MB!"
    else
      begin
        Product.transaction do
          product = Product.new(hash)
          product.save
          sp = SharedProduct.create(:code => product.code, :name => product.name, :standard => product.standard,
            :unit => product.unit, :product_id => product.id)
          if img
            path,msg = Product.upload_img(img, @store.id, product.id)
            if path == ""
              product.destroy
              sp.destroy
              flash[:notice] = msg
            else
              product.update_attribute("img_url", path)
              flash[:notice] = "新建成功!"
            end
          else
            flash[:notice] = "新建成功!"
          end
        end
      rescue
        flash[:notice] = "新建失败!"
      end
    end
    redirect_to "/stores/#{@store.id}/storages"
  end

  def edit    #1备注、2编辑、3快速入库、4预警、5忽略
    @set_product_types = params[:set_product_types].to_i
    id = params[:id].to_i
    @product = Product.find_by_id(id)
    if @set_product_types == 2
      @mat_type = Category.where(["store_id=? and types=?", @store.id, Category::TYPES[:material]])
      @revi_time = Product::REVIST_TIME
    end
  end

  def update  #1备注、2编辑、3快速入库、4预警、5忽略
    set_product_types = params[:set_product_types].to_i
    Product.transaction do
      product = Product.find_by_id(params[:id].to_i)
      @status = 1
      begin
        if set_product_types == 1
          remark = params[:remark]
          product.update_attribute("remark", remark)
          flash[:notice] = "设置成功!"
        elsif set_product_types == 2
          img = params[:p_image]
          is_shelves = params[:is_shelves].nil? || params[:is_shelves].to_i==0 ? false : true
          auto_revi = params[:auto_revist].nil? ? false : true
          is_added = params[:is_added].nil? ? false : true
          hash = {
            :name => params[:name], :code => params[:code].nil? || params[:code]=="" ? "123456" : params[:code],
            :base_price => params[:base_price], :sale_price => params[:sale_price], :t_price => params[:t_price],
            :description => params[:description], :introduction => params[:introduction], :types => Product::TYPES[:MATERIAL],
            :service_code => Product.make_service_code(4,"product", "service_code"), :status => Product::STATUS[:NORMAL],
            :is_shelves => is_shelves, :is_service => Product::IS_SERVICE[:NO], :store_id => @store.id,
            :standard => params[:standard], :unit => params[:unit], :is_auto_revist => auto_revi,
            :auto_time => auto_revi ? params[:revist_time].to_i : nil, :revist_content => auto_revi ? params[:revist_cont] : nil,
            :prod_point => is_shelves ? params[:p_point].to_i : nil, :category_id => params[:types].to_i,
            :is_added => is_added,
            :deduct_percent => is_shelves ? (params[:xs_t_type].to_i==2 ? params[:xs_t].to_f*params[:sale_price].to_f/100 : nil) : nil,
            :deduct_price => is_shelves ? (params[:xs_t_type].to_i==1 ? params[:xs_t].to_f : nil) : nil,
            :techin_percent => is_shelves && is_added ? (params[:js_t_type].to_i==2 ? params[:js_t].to_f*params[:sale_price].to_f/100 : nil) : nil,
            :techin_price => is_shelves && is_added ? (params[:js_t_type].to_i==1 ? params[:js_t].to_f : nil) : nil,
            :show_on_ipad => params[:show_on_pad].nil? || params[:show_on_pad].to_i==0 ? false : true,
            :cost_time => params[:cost_time].nil? ? nil : params[:cost_time].to_i
          }
          if img && img.size > Product::MAX_SIZE
            flash[:notice] = "编辑失败,产品图片尺寸最大不得超过5MB!"
          else
            sp = SharedProduct.find_by_product_id(product.id)
            if img
              path,msg = Product.upload_img(img, @store.id, product.id)
              if path == ""
                flash[:notice] = msg
              else
                hash.merge!({:img_url => path})
                product.update_attributes(hash)
                sp.update_attributes(:code => product.code, :name => product.name, :standard => product.standard, :unit => product.unit) if sp
                flash[:notice] = "编辑成功!"
              end
            else
              product.update_attributes(hash)
              sp.update_attributes(:code => product.code, :name => product.name, :standard => product.standard, :unit => product.unit) if sp
              flash[:notice] = "编辑成功!"
            end
          end
        elsif set_product_types == 3
          fast_num = params[:fast_num].to_f
          product.update_attribute("storage", fast_num)
          flash[:notice] = "设置成功!"
        elsif set_product_types == 4
          low_warning = params[:low_warning].nil? || params[:low_warning]=="" ? 0 : params[:low_warning].to_f
          product.update_attribute("low_warning", low_warning)
          flash[:notice] = "设置成功!"
        elsif set_product_types == 5
          if product.is_ignore == true
            product.update_attribute("is_ignore", false)
          else
            product.update_attribute("is_ignore", true)
          end
          flash[:notice] = "设置成功!"
        end
      rescue
        @status = 0
      end
    end
  end

  def destroy
    Product.transaction do
      @status = 1
      begin
        prod = Product.find_by_id(params[:id].to_i)
        prod.update_attribute("status", Product::STATUS[:DELETED])
        sp = SharedProduct.find_by_product_id(prod.id)
        sp.destroy if sp
      rescue
        @status = 0
      end
      render :json => {:status => @status}
    end
  end

  def prod_valid #新建或者编辑产品时验证
    name = params[:name]
    code = params[:code]
    id = params[:id].to_i
    status = 1
    msg = ""
    if id==0
      obj = Product.where(["store_id=? and status=? and types=? and name=?", @store.id, Product::STATUS[:NORMAL],
          Product::TYPES[:MATERIAL], name]).first
      if obj.nil?
        if code && code.strip!=""
          obj = Product.where(["store_id=? and status=? and types=? and code=?", @store.id, Product::STATUS[:NORMAL],
              Product::TYPES[:MATERIAL], code]).first
          if obj
            status = 0
            msg = "已有相同条形码的产品!"
          end
        end
      else
        status = 0
        msg = "已有相同名称的产品!"
      end
    else
      obj = Product.where(["store_id=? and status=? and types=? and name=? and id!=?", @store.id, Product::STATUS[:NORMAL],
          Product::TYPES[:MATERIAL], name, id]).first
      if obj.nil?
        if code && code.strip!=""
          obj = Product.where(["store_id=? and status=? and types=? and code=? and id!=?", @store.id, Product::STATUS[:NORMAL],
              Product::TYPES[:MATERIAL], code, id]).first
          if obj
            status = 0
            msg = "已有相同条形码的产品!"
          end
        end
      else
        status = 0
        msg = "已有相同名称的产品!"
      end
    end
    render :json => {:status => status, :msg => msg}
  end

  #打印库存清单
  def print_all_prods
    @products = Product.find_by_sql(["select p.*, c.name cname from products p inner join categories c
        on p.category_id=c.id where p.store_id=? and p.status=? and p.types=?",@store.id, Product::STATUS[:NORMAL],
        Product::TYPES[:MATERIAL]])
  end

  def get_title
    @title = "库存列表"
  end
  
end