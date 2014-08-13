#encoding: utf-8
class Product < ActiveRecord::Base
  include ApplicationHelper
  require 'net/http'
  require "uri"
  require 'openssl'
  require 'zip/zip'
  require 'zip/zipfilesystem'
  require 'mini_magick'
  has_many :sale_prod_relations
  has_many :res_prod_relations
  has_many :station_service_relations
  has_many :order_prod_relations
  has_many :pcard_prod_relations
  has_many :prod_mat_relations
  has_many :image_urls
  has_many :stations, :through => :station_service_relations
  belongs_to :store
  belongs_to :category
  TYPES = {:MATERIAL => 0, :SERVICE => 1}  #0物料(商品) 1服务
  STATUS = {:DELETED => 0, :NORMAL => 1}  #状态 0删除 1正常
  IS_SERVICE = {:YES => true, :NO => false}
  SHOW_ON_IPAD ={:NO=>0,:YES=>1} #是否在ipad端显示 0不显示 1显示
  REVIST_TIME = [24,48,72,96,120]
  IS_AUTO = {:YES=>1,:NO=>0}  #是否自动回访
  IS_ADDED = {:YES=>1,:NO=>0}   #是否要施工
  SINGLE_TYPE = {:SIN =>0,:DOUB =>1} #单次服务0 套装 1
  IS_IGNORE = {:YES => 1, :NO => 0} #是否忽略库存预警， 1是 0否
  IS_SHELVES = {:YES => true, :NO => false} #是否上架 
  scope :is_service, where(:is_service => true)
  scope :is_normal, where(:status => true)
  scope :commonly_used, where(:commonly_used => true)
  PACK_SERVIE  = {0=>"产品套装服务"}
  PACK ={:PACK => 0}
  PER_PAGE = 20
  #搜索产品列表
  PROD_PICSIZE = [100]
  MAX_SIZE = 5242880  #图片尺寸最大不得超过5MB
  #产品列表
  def self.products_arr store_id,product_name,types
    cards,services,products = [],[],[]
    status = 1
    msg = ""
    begin
      case types
      when 0  #0为产品
        sql = ["store_id=? and status=? and types=? and is_shelves=?", store_id, STATUS[:NORMAL], TYPES[:MATERIAL], 1]
        unless product_name.nil? || product_name.strip==""
          sql[0] += " and name like ?"
          sql << "%#{product_name.gsub(/[%_]/){|n|'\\'+n}}%"
        end
        prods = Product.where(sql)
        prods.each do |p|
          hash = {:description => p.description, :id => p.id, :img_url => p.img_url, :introduction => p.introduction,
            :name => p.name, :types => p.types.to_i, :sale_price => p.sale_price.to_f.round(2), :isSelected => 0,
            :storage => p.storage.to_f.round(2)
          }
          products << hash if hash[:storage] > 0
        end if prods
      when 1  #1为服务
        sql = ["store_id=? and status=? and types=?", store_id, STATUS[:NORMAL], TYPES[:SERVICE]]
        unless product_name.nil? || product_name.strip==""
          sql[0] += " and name like ?"
          sql << "%#{product_name.gsub(/[%_]/){|n|'\\'+n}}%"
        end
        servs = Product.where(sql)
        servs.each do |p|
          hash = {:description => p.description, :id => p.id, :img_url => p.img_url, :introduction => p.introduction,
            :name => p.name, :types => p.types.to_i, :sale_price => p.sale_price.to_f.round(2), :isSelected => 0,
          }
          s_prods = ProdMatRelation.find_by_sql(["select min(p.storage/pmr.material_num) l_stor from products p
            inner join prod_mat_relations pmr on p.id=pmr.material_id where pmr.product_id=?", p.id]).first
          hash[:storage] = s_prods.nil? || s_prods.l_stor.nil? ? -1 : s_prods.l_stor.to_i
          services << hash if hash[:storage]!=0
        end if servs
      when 2  #2为卡类
        p_sql = ["store_id=? and status=?", store_id, PackageCard::STAT[:NORMAL]]
        sv_sql = ["store_id=? and status=?", store_id, SvCard::STATUS[:NORMAL]]
        unless product_name.nil? || product_name.strip==""
          p_sql[0] += " and name like ?"
          p_sql << "%#{product_name.gsub(/[%_]/){|n|'\\'+n}}%"
          sv_sql[0] += " and name like ?"
          sv_sql << "%#{product_name.gsub(/[%_]/){|n|'\\'+n}}%"
        end
        pcards = PackageCard.where(p_sql)
        svcards = SvCard.where(sv_sql)
        pcards.each do |p|
          hash = {:description => p.description, :id => p.id, :img_url => p.img_url, :name => p.name, :types => 2,
            :price => p.price.to_f.round(2), :is_selected => 0, :is_new => 1}
          prods = PcardProdRelation.find_by_sql(["select p.name from pcard_prod_relations ppr inner join products p
            on ppr.product_id=p.id where ppr.package_card_id=?", p.id]).map(&:name).uniq.join(",")
          hash[:products] = prods
          cards << hash
        end if pcards.any?

        svcards.each do |p|
          hash = {:description => p.description, :id => p.id, :img_url => p.img_url, :name => p.name, :types => p.types.to_i,
            :price => p.price.to_f.round(2), :is_selected => 0, :is_new => 1}
          prods = p.apply_content.nil? || p.apply_content=="" ? "" : Product.where(["id in (?) and status=?",
              p.apply_content.split(",").collect{|i|i.to_i}, STATUS[:NORMAL]]).map(&:name).uniq.join(",")
          hash[:products] = prods
          cards << hash
        end if svcards.any?

      end
    rescue
      status = 0
      msg = "数据错误!"
    end
    return [status, msg, cards, services, products]
  end

  #产品和服务的列表
  def self.products_and_services store_id
    status = 1
    msg = ""
    array = []
    begin
      fast_prods = Product.where(["store_id=? and status=? and is_shelves=?", store_id,
          STATUS[:NORMAL], 1]).group_by{|fp|fp.category_id}
      fast_prods.each do |k, v|
        hash = {:id => k.to_i, :name => k.to_i==0 ? "套装服务" : Category.find_by_id( k.to_i).name}
        arr = []
        v.each do |prod|
          hash2 = {:id => prod.id, :name => prod.name, :sale_price => prod.sale_price.to_f.round(2),
            :is_selected => 0, :types => prod.types}
          if prod.types == TYPES[:MATERIAL]
            hash2[:storage] = prod.storage.to_f.round(2)
          else
            s_prods = ProdMatRelation.find_by_sql(["select min(p.storage/pmr.material_num) l_stor from products p
            inner join prod_mat_relations pmr on p.id=pmr.material_id where pmr.product_id=?", prod.id]).first
            hash2[:storage] = s_prods.nil? || s_prods.l_stor.nil? ? -1 : s_prods.l_stor.to_i
          end
          arr << hash2 if hash2[:storage]>0 || hash2[:storage] < 0
        end
        hash[:prod] = arr
        array << hash if arr.any?
      end if fast_prods.any?
    rescue
      status = 0
      msg = "数据错误!"
    end
    return [status, msg, array]
  end

  
  #生成产品的service_code
  def self.make_service_code(length,model_n,code_name)
    chars = (1..9).to_a + ("a".."z").to_a + ("A".."Z").to_a
    code=(1..length).inject(Array.new) {|codes| codes << chars[rand(chars.length)]}.join("")
    codes=eval(model_n.capitalize).all.map(&:"#{code_name}")
    if codes.index(code)
      make_service_code(length,model_n,code_name)
    else
      return code
    end
  end

  #上传产品的图片
  def self.upload_img img, store_id, product_id
    path = ""
    msg = ""
    root_path = "#{Rails.root}/public"
    dirs=["/prodImgs","/#{store_id}", "/#{product_id}"]
    begin
      dirs.each_with_index {|dir,index| Dir.mkdir root_path+dirs[0..index].join   unless File.directory? root_path+dirs[0..index].join }
      img_name = img.original_filename
      filename="#{dirs.join}/prod#{product_id}_img."+ img_name.split(".").reverse[0]
      File.open(root_path+filename, "wb")  {|f|  f.write(img.read) }  #存入原图
      mini_img = MiniMagick::Image.open root_path+filename,"rb"
      PROD_PICSIZE.each do |size|
        new_file="#{dirs.join}/prod#{product_id}_img_#{size}."+ filename.split(".").reverse[0]
        width = size > mini_img["width"] ? mini_img["width"] : size
        height = mini_img["height"].to_f*width/mini_img["width"].to_f > 100 ?  100 : width
        mini_img.run_command("convert #{root_path+filename}  -resize #{width}x#{height} #{root_path+new_file}")
      end
      path = filename
    rescue
      msg = "图片上传失败!"
    end
    return [path, msg]
  end

  #拆分产品和卡类数据
  # //type:0-产品  1-服务  2－打折卡  3－套餐卡  4-储值卡 //0_id_count_price //1_id_count_price //2_id_isNew_price //3_id_isNew_price(新的)
  # => //4_id_isNew_price_password //3_id_isNew_price_proId=num(老的)
  # prods="0_1_2_100,1_2_1,2_1_1_30,3_1_1_100,3_1_0_100_1=2,4_1_1_100_123"
  def self.order_products prods
    arr = prods.split(",")
    prod_arr = []
    service_arr = []
    svcard_arr = []
    pcard_arr = []
    stored_arr = []
    arr.each do |p|
      if p.split("_")[0].to_i == 0
        #p  0_id_count
        prod_arr << p.split("_")
      elsif p.split("_")[0].to_i == 1
        #p 1_id_prod1=price1_prod2=price2_totalprice_realy_price
        service_arr << p.split("_")
      elsif p.split("_")[0].to_i == 2
        #p 2_id
        svcard_arr << p.split("_")
      elsif p.split("_")[0].to_i == 3
        #p 3_id_has_p_card_prodId=prodId
        pcard_arr << p.split("_")
      elsif p.split("_")[0].to_i == 4
        stored_arr <<  p.split("_")
      end
    end
    [prod_arr,service_arr,svcard_arr,pcard_arr,stored_arr]
  end

  def self.get_prod_type_and_storage  product_id    #获取某个产品或者服务的types和库存
    prod = Product.find_by_id(product_id)
    types = prod.types
    storage = 0
    if types = TYPES[:MATERIAL]
      storage = prod.storage.to_f.round(2)
    else
      s_prods = ProdMatRelation.find_by_sql(["select min(p.storage/pmr.material_num) l_stor from products p
            inner join prod_mat_relations pmr on p.id=pmr.material_id where pmr.product_id=?", prod.id]).first
      storage = s_prods.nil? || s_prods.l_stor.nil? ? -1 : s_prods.l_stor.to_i
    end
    return [types, storage]
  end
end
