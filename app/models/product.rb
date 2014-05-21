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
  #产品列表
  def self.products_arr store_id,product_name,types #0 为产品 1 为服务 2 为卡类
    if types==2
      package_card = PackageCard.find_by_sql("SELECT id,name,img_url,revist_content,status from package_cards
                  where store_id = #{store_id} and name like '#{product_name}' and status = #{PackageCard::STAT[:NORMAL]}")
      svcard = SvCard.find_by_sql("select id,name,img_url,types,description from sv_cards 
                  where store_id = #{store_id} and name like '#{product_name}' and status = #{SvCard::STATUS[:NORMAL]}")
      product_list = {:package_card =>package_card, :svcard=> svcard}
    else
      product_list = Product.find_by_sql("SELECT id,name,types,description,introduction,img_url,status
            FROM products where store_id=#{store_id} and name like '#{product_name}'
            and is_service = #{types} and status = #{STATUS[:NORMAL]} order by status")
    end
    return product_list
  end
end
