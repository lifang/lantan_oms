#encoding: utf-8
class Staff < ActiveRecord::Base
  require 'fileutils'
  require 'mini_magick'
  has_many :staff_role_relations, :dependent=>:destroy
  has_many :roles, :through => :staff_role_relations, :foreign_key => "role_id"
  has_many :salary_details
  has_many :work_records
  has_many :salaries
  has_many :station_staff_relations
  has_many :stations, :through => :station_staff_relations
  has_many :train_staff_relations
  has_many :violation_rewards
  has_many :staff_gr_records
  has_many :month_scores
  has_many :product_losses
  belongs_to :store
  has_many  :tech_orders
  STAFF_PICSIZE = [100]
  MAX_SIZE = 5242880  #图片尺寸最大不得超过5MB
  STATUS = {:normal => 0, :afl => 1, :vacation => 2, :resigned => 3, :deleted => 4}
  STATUS_NAME = {0 => "在职", 1 => "请假", 2 => "休假", 3 => "离职", 4 => "删除"}
  VALID_STATUS = [STATUS[:normal], STATUS[:afl], STATUS[:vacation]]

  #门店员工职务
  S_COMPANY = {:BOSS=>0,:TECHNICIAN =>1, :CHIC=>2,:FRONT =>3,:OTHER=>4} #0老板 1技师 2店长 3接待  4其他
  N_COMPANY = {0 => "老板", 1=>"技师",2=>"店长",3=>"接待",4=>"其他"}
  LEVELS = {0=>"高级",1=>"中级",2=>"初级"}  #技师等级
  WORKING_STATS = {:FORMAL => 1, :PROBATION => 0}   #在职状态 0试用 1正式
  S_WORKING_STATS = {1 => "正式", 0 => "实习"}
  IS_DEDUCT = {:YES => 1, :NO =>0} #是否参加提成，1是 0否
  S_IS_DEDUCT = {1 => "是", 0 => "否"}
  #教育程度
  N_EDUCATION = {0 => "研究生", 1 => "本科", 2 => "专科", 3 => "高中", 4 => "初中",
    5 => "小学", 6 => "无"}
  S_EDUCATION = {:GRADUATE => 0,  :UNIVERSITY => 1, :COLLEGE => 2, :SENIOR => 3, :JUNIOR => 4, :PRIMARY => 5, :NONE => 6}
  #员工性别
  N_SEX = {0 => "男", 1 => "女"}
  attr_accessor :password
  
  PerPage = 20
  scope :normal, where(:status => STATUS[:normal])
  scope :valid, where(:status => VALID_STATUS)
  scope :not_deleted, where("status != #{STATUS[:deleted]}")


  def has_password?(submitted_password)
		encrypted_password == encrypt(submitted_password)
	end

  def encrypt_password
    self.encrypted_password=encrypt(password)
  end


  private
  def encrypt(string)
    self.salt = make_salt if new_record?
    secure_hash("#{salt}--#{string}")
  end

  def make_salt
    secure_hash("#{Time.new.utc}--#{password}")
  end

  def secure_hash(string)
    Digest::SHA2.hexdigest(string)
  end

  def self.staff_and_order staff_id,store_id
    #本月完成订单数量和总金额
    stafforders = Order.find_by_sql("SELECT o.id,o.price from orders o where date_format(o.created_at,'%Y-%m')=date_format(now(),'%Y-%m') 
        and o.status in (#{Order::STATUS[:BEEN_PAYMENT]},#{Order::STATUS[:FINISHED]}) and o.front_staff_id = #{staff_id} and o.store_id=#{store_id}")
    order_count = stafforders.length
    has_pay = stafforders.map(&:price).inject(0) { |sum,e| sum + e }

    #当前正在进行中的订单
    order_now = Order.find_by_sql("SELECT o.id,o.code,cn.num,o.price sum_price from orders o INNER JOIN  car_nums cn on cn.id=o.car_num_id
        where date_format(o.created_at,'%Y-%m')=date_format(now(),'%Y-%m')
        and o.status in (#{Order::STATUS[:NORMAL]},#{Order::STATUS[:SERVICING]},#{Order::STATUS[:WAIT_PAYMENT]}) and o.front_staff_id = #{staff_id} and o.store_id=#{store_id}")
    order_detail = OrderProdRelation.joins("opr inner join products p on p.id=opr.product_id").
      select("p.name,opr.order_id,opr.price,opr.pro_num,opr.total_price,opr.t_price").
      where(["order_id in (?)", order_now.map(&:id)]).group_by{|order_pro| order_pro.order_id}
    
    orders_now = []
    order_now.each do |order|
      order_attr = order.attributes
      order_attr['detail'] = order_detail.present? && order_detail[order.id].present? ? order_detail[order.id] : []
      orders_now << order_attr
    end
    return [order_count,has_pay,orders_now]
  end

  #上传产品的图片
  def self.upload_img img, store_id, staff_id
    path = ""
    msg = ""
    root_path = "#{Rails.root}/public"
    dirs=["/staffImgs","/#{store_id}", "/#{staff_id}"]
    begin
      dirs.each_with_index {|dir,index| Dir.mkdir root_path+dirs[0..index].join   unless File.directory? root_path+dirs[0..index].join }
      img_name = img.original_filename
      filename="#{dirs.join}/prod#{staff_id}_img."+ img_name.split(".").reverse[0]
      File.open(root_path+filename, "wb")  {|f|  f.write(img.read) }  #存入原图
      mini_img = MiniMagick::Image.open root_path+filename,"rb"
      STAFF_PICSIZE.each do |size|
        new_file="#{dirs.join}/prod#{staff_id}_img_#{size}."+ filename.split(".").reverse[0]
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
