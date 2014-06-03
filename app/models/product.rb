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
  PROD_PICSIZE = [100]
  MAX_SIZE = 5242880  #图片尺寸最大不得超过5MB
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

end
