#encoding: utf-8
class Store < ActiveRecord::Base
  require 'mini_magick'
  has_many :stations
  has_many :reservations
  has_many :products
  has_many :sales
  has_many :work_orders
  has_many :svc_return_records
  has_many :goal_sales
  has_many :message_records
  has_many :notices
  has_many :package_cards
  has_many :staffs
  has_many :materials
  has_many :suppliers
  has_many :month_scores
  has_many :complaints
  has_many :sv_cards
  has_many :store_chain_relations
  has_many :depots
  has_many :customer_store_relations
  has_many :customers, :through => :customer_store_relations

  belongs_to :city
  has_many :roles

  AUTO_SEND = {:YES=>1,:NO=>0}  #是否自动发送 1 自动发送 0 不自动发送
  STATUS = {
    :CLOSED => 0,       #0该门店已关闭，1正常营业，2装修中, 3已删除
    :OPENED => 1,
    :DECORATED => 2,
    :DELETED => 3
  }
  S_STATUS = {
    0 => "已关闭",
    1 => "正常营业",
    2 => "装修中",
    3 => "已删除"
  }
  EDITION_LV ={       #门店使用的系统的版本等级
    0 => "实用版",
    1 => "精英版",
    2 => "豪华版",
    3 => "旗舰版"
  }
  EDITION_NAME = {:FACTUARL => 0} # 使用版  0
  IS_CHAIN = {:YES => 1,:NO => 0} #是否有关联的连锁店

  CASH_AUTH = {:NO => 0, :YES => 1} #是否有在pad上收银的权限
  MAX_SIZE = 5242880  #图片尺寸最大不得超过5MB
  STORE_PICSIZE = [1000,50]
  
  def self.upload_img(img,store_id)
    path = ""
    msg = ""
    if img.size > MAX_SIZE
      msg = "上传失败,图片最大不得超过5MB!"
    else
      root_path = "#{Rails.root}/public"
      dirs=["/storeImgs","/#{store_id}"]
      begin
        dirs.each_with_index {|dir,index| Dir.mkdir root_path+dirs[0..index].join   unless File.directory? root_path+dirs[0..index].join }
        img_name = img.original_filename
        filename="#{dirs.join}/store#{store_id}_img."+ img_name.split(".").reverse[0]
        File.open(root_path+filename, "wb")  {|f|  f.write(img.read) }  #存入原图
        mini_img = MiniMagick::Image.open root_path+filename,"rb"
        STORE_PICSIZE.each do |size|
          new_file="#{dirs.join}/store#{store_id}_img_#{size}."+ filename.split(".").reverse[0]
          width = size > mini_img["width"] ? mini_img["width"] : size
          height = mini_img["height"].to_f*width/mini_img["width"].to_f > 345 ?  345 : width
          mini_img.run_command("convert #{root_path+filename}  -resize #{width}x#{height} #{root_path+new_file}")
        end
        path = filename
      rescue
        msg = "图片上传失败!"
      end
    end
    return [path, msg]
  end

end
