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
  has_many :materials, :through => :prod_mat_relations
  has_many :svcard_prod_relations
  has_many :image_urls
  has_many :stations, :through => :station_service_relations
  belongs_to :store
  belongs_to :category
  PRODUCT_END = 6
  BEAUTY_SERVICE = 9
  PROD_TYPES = {:PRODUCT =>0, :SERVICE =>1}  #0 为产品 1 为服务
  STATUS = {:DELETED => 0, :NORMAL => 1}  #状态 0删除 1正常
  SHOW_ON_IPAD ={:NO=>0,:YES=>1} #是否在ipad端显示 0不显示 1显示
  REVIST_TIME = [24,48,72,96,120]
  IS_AUTO = {:YES=>1,:NO=>0}
  IS_ADDED = {:YES=>1,:NO=>0}
  SINGLE_TYPE = {:SIN =>0,:DOUB =>1} #单次服务0 套装 1
  scope :is_service, where(:is_service => true)
  scope :is_normal, where(:status => true)
  scope :commonly_used, where(:commonly_used => true)
  PACK_SERVIE  = {0=>"产品套装服务"}
  PACK ={:PACK => 0}
end
