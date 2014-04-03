#encoding: utf-8
#require 'barby'
#require 'barby/barcode/ean_13'
#require 'barby/outputter/custom_rmagick_outputter'
#require 'barby/outputter/rmagick_outputter'
class Material < ActiveRecord::Base
  has_many :prod_mat_relations
  has_many :material_losses
  has_many :mat_order_items
  has_many :back_good_records
  has_many :material_orders, :through => :mat_order_items do  
    def not_all_in
      where("m_status not in (?) and status != ?",[3,4], MaterialOrder::STATUS[:cancel])
    end
  end
  has_many :mat_out_orders
  has_many  :mat_in_orders
  has_many :prod_mat_relations
  has_many :mat_depot_relations
  has_many :pcard_material_relations
  has_many :depots, :through => :mat_depot_relations
  belongs_to :category
  attr_accessor :ifuse_code, :code_value

  before_create :generate_barcode
  after_create :generate_barcode_img
  STATUS = {:NORMAL => 0, :DELETE => 1}  #物料状态 0为正常 1 为删除 0 为没上架 1 为上架
  TYPES_NAMES = {0 => "清洁用品", 1 => "美容用品", 2 => "装饰产品", 3 => "配件产品", 4 => "电子产品",
    5 =>"其他产品",6 => "辅助工具", 7 => "劳动保护"}
  TYPES = { :CLEAN_PROD =>0, :BEAUTY_PROD =>1,:DECORATE_PROD =>2, :ACCESSORY_PROD =>3, :ELEC_PROD =>4,
    :OTHER_PROD => 5, :ASSISTANT_TOOL => 6, :LABOR_PROTECT => 7}
  PRODUCT_TYPE = [TYPES[:CLEAN_PROD], TYPES[:BEAUTY_PROD], TYPES[:DECORATE_PROD],
    TYPES[:ACCESSORY_PROD], TYPES[:ELEC_PROD], TYPES[:OTHER_PROD]]
  MAT_IN_PATH = "#{File.expand_path(Rails.root)}/public/uploads/mat_in/%s"
  MAT_OUT_PATH = "#{File.expand_path(Rails.root)}/public/uploads/mat_out/%s"
  MAT_CHECKNUM_PATH = "#{File.expand_path(Rails.root)}/public/uploads/mat_check/%s"
  IS_IGNORE = {:YES => 1, :NO => 0} #是否忽略库存预警， 1是 0否
  DEFAULT_MATERIAL_LOW = 0    #默认库存预警为0
  scope :normal, where(:status => STATUS[:NORMAL]) 

end
