#encoding: utf-8
class Product < ActiveRecord::Base
  include ApplicationHelper
  require 'net/http'
  require "uri"
  require 'openssl'
  require 'zip/zip'
  require 'zip/zipfilesystem'
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
  PROD_TYPES = {:PRODUCT =>0, :SERVICE =>1}  #0 为产品 1 为服务
  TYPES = {:MATERIAL => 0, :SERVICE => 1}  #0物料(商品) 1服务
  STATUS = {:DELETED => 0, :NORMAL => 1}  #状态 0删除 1正常
  SHOW_ON_IPAD ={:NO=>0,:YES=>1} #是否在ipad端显示 0不显示 1显示
  REVIST_TIME = [24,48,72,96,120]
  IS_AUTO = {:YES=>1,:NO=>0}
  IS_ADDED = {:YES=>1,:NO=>0}
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
  def self.products_arr store_id,product_name,types #0 为产品 1 为服务 2 为卡类
    cards = []
    services = []
    products = []
    if types.to_i==2
      package_cards = PackageCard.find_by_sql("SELECT id,name,img_url,description,price from package_cards
                  where store_id = #{store_id} and name like '#{product_name}' and status = #{PackageCard::STAT[:NORMAL]}")
      package_card_id = package_cards.map(&:id)
      #      适用项目
      pccard_product = Product.find_by_sql(["select p.name,ppr.package_card_id from products p
                INNER JOIN pcard_prod_relations ppr on p.id = ppr.product_id where p.status=#{STATUS[:NORMAL]}
                and p.is_shelves=#{IS_SHELVES[:YES]} and ppr.package_card_id in (?)",package_card_id]).group_by{|prod| prod.package_card_id}

      svcards = SvCard.find_by_sql("select id,name,img_url,types,description,price,apply_content from sv_cards
                  where store_id = #{store_id} and name like '#{product_name}' and status = #{SvCard::STATUS[:NORMAL]}")

      (package_cards || []).each do |package_card|
        package_card["types"] = 2
        package_card['isseleted'] = 0
        package_card["products"] = pccard_product[package_card.id].nil? ? [] : pccard_product[package_card.id].map(&:name).join(",")
        cards << package_card
      end
      (svcards || []).each do |svcard|
        svcard_product=[]
        if svcard.types.to_i == 0
          product_id = svcard.apply_content.split(",") if svcard.apply_content
          svcard_product = Product.select("name").where(["id in (?)",product_id]).where("status = #{SvCard::STATUS[:NORMAL]}").map(&:name).join(",")
        end
        svcard['isseleted'] = 0
        svcard["products"] = svcard_product
        cards << svcard
      end
    else
      product_list = Product.find_by_sql("SELECT id,name,types,description,introduction,img_url,status,sale_price,storage
            FROM products where store_id=#{store_id} and name like '#{product_name}'
            and is_service = #{types} and status = #{STATUS[:NORMAL]} and is_shelves =#{IS_SHELVES[:YES]} order by status")
      product_lists =[]

      if types.to_i==1
        service_ma = Product.find_by_sql(["select min(p.storage/pmr.material_num) cishu,pmr.product_id from products p INNER JOIN prod_mat_relations pmr on p.id=pmr.material_id
                        where p.status = #{STATUS[:NORMAL]} and p.types=#{TYPES[:MATERIAL]} and p.is_shelves=#{IS_SHELVES[:NO]} and
                        pmr.product_id in (?) GROUP BY pmr.product_id",product_list.map(&:id)]).group_by{|serverse| serverse.product_id}
        product_list.each do |product|
          product['isseleted'] = 0
          product['several_times'] = service_ma[product.id].nil? ? -1 : service_ma[product.id].first.cishu.to_i
          product_lists << product
        end
        services = product_list
      else
        product_list.each do |product|
          product['isseleted'] = 0
          product['several_times'] = product.storage.to_i
          product_lists << product
        end
        products = product_list
      end
    end
    return [cards,services, products]
  end

  #产品和服务的列表
  def self.products_and_services store_id,name

    packagecards = []
    #套餐卡
    package_cards = PackageCard.find_by_sql("SELECT id,name,img_url,description,price from package_cards
                  where store_id = #{store_id} and status = #{PackageCard::STAT[:NORMAL]}")
    package_card_id = package_cards.map(&:id)
    #      适用项目
    pccard_product = Product.find_by_sql(["select p.name,ppr.package_card_id from products p
                INNER JOIN pcard_prod_relations ppr on p.id = ppr.product_id where p.status=#{STATUS[:NORMAL]}
                and p.is_shelves=#{IS_SHELVES[:YES]} and ppr.package_card_id in (?)",package_card_id]).group_by{|prod| prod.package_card_id}

    svcards = SvCard.find_by_sql("select id,name,img_url,types,description,price,apply_content from sv_cards
                  where store_id = #{store_id} and status = #{SvCard::STATUS[:NORMAL]}").group_by{|svcard| svcard.types}

    (package_cards || []).each do |package_card|
      package_card["types"] = 2
      package_card["products"] = pccard_product[package_card.id].nil? ? [] : pccard_product[package_card.id].map(&:name).join(",")
      packagecards << package_card
    end
    #打折卡
    discount_cards = []
    (svcards[0] || []).each do |svcard|
      svcard_product=[]
      if svcard.types.to_i == 0
        product_id = svcard.apply_content.split(",") if svcard.apply_content
        svcard_product = Product.select("name").where(["id in (?)",product_id]).where("status = #{SvCard::STATUS[:NORMAL]}").map(&:name).join(",")
      end
      svcard["products"] = svcard_product
      discount_cards << svcard
    end
    #储值卡
    stored_cards = []
    (svcards[1] || []).each do |svcard|
      svcard_product=[]
      if svcard.types.to_i == 0
        product_id = svcard.apply_content.split(",") if svcard.apply_content
        svcard_product = Product.select("name").where(["id in (?)",product_id]).where("status = #{SvCard::STATUS[:NORMAL]}").map(&:name).join(",")
      end
      svcard["products"] = svcard_product
      stored_cards << svcard
    end
    #产品或者服务部分
    product_list = Product.find_by_sql("select p.id,p.name,p.sale_price,p.category_id,p.storage,c.types from products p
          INNER JOIN categories c on p.category_id = c.id where p.is_shelves = #{IS_SHELVES[:YES]}
          and p.status=#{STATUS[:NORMAL]} and c.store_id=#{store_id} and p.name like '#{name}' ")
    product_types = product_list.group_by{|product| product.types}

    service_ma = Product.find_by_sql(["select min(p.storage/pmr.material_num) cishu,pmr.product_id from products p INNER JOIN prod_mat_relations pmr on p.id=pmr.material_id
                        where p.status = #{STATUS[:NORMAL]} and p.types=#{TYPES[:MATERIAL]} and p.is_shelves=#{IS_SHELVES[:NO]} and
                        pmr.product_id in (?) GROUP BY pmr.product_id",product_list.map(&:id)]).group_by{|serverse| serverse.product_id}
    product_lists = []
    product_types[1].each do |product|
      product['several_times'] = service_ma[product.id].nil? ? -1 : service_ma[product.id].first.cishu.to_i
      product_lists << product
    end if product_types && product_types[1]

    product_types[0].each do |product|
      product['several_times'] = product.storage.to_i
      product_lists << product
    end if product_types && product_types[0]
    product_arr = product_lists.group_by{|product| product.category_id}
    categories = Category.where(["id in (?) ",product_list.map(&:category_id)]).select("id,name")
    categories.each do |category|
      category["prod"] = product_arr[category.id]
    end
    return categories
  end
end
