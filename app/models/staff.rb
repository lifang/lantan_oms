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

  def self.staff_and_order staff_id,store_id
    status = 1
    msg = ""
    order_count,has_pay,orders_now = 0,0,[]
    begin
      #本月完成订单数量和总金额
      stafforders = Order.find_by_sql("select o.id,o.price from orders o where date_format(o.created_at,'%Y-%m')=date_format(now(),'%Y-%m')
        and o.status in (#{Order::STATUS[:BEEN_PAYMENT]},#{Order::STATUS[:FINISHED]}) and o.front_staff_id = #{staff_id} and o.store_id=#{store_id}")
      order_count = stafforders.length
      has_pay = stafforders.map(&:price).inject(0) { |sum,e| sum + e }

      #当前正在进行中的订单
      orders = Order.find_by_sql(["select o.id,o.code,o.price sum_price,cn.num from orders o inner join car_nums cn
      on o.car_num_id=cn.id where date_format(o.created_at,'%Y-%m')=? and o.status in (?) and o.front_staff_id=? and o.store_id=?", Time.now.strftime("%Y-%m"),
        [Order::STATUS[:NORMAL],Order::STATUS[:SERVICING],Order::STATUS[:WAIT_PAYMENT]], staff_id, store_id])
      orders.each do |o|
        hash = {:id => o.id, :code => o.code, :num => o.num, :sum_price => o.sum_price.to_f.round(2)}
        prod_detail = []
        oprs = OrderProdRelation.where(["order_id=?", o.id])
        oprs.each do |opr|
          hash2 = {}
          prod = opr.prod_types == OrderProdRelation::PROD_TYPES[:SERVICE] ? Product.find_by_id(opr.item_id)
            : opr.prod_types == OrderProdRelation::PROD_TYPES[:P_CARD] ? PackageCard.find_by_id(opr.item_id) : SvCard.find_by_id(opr.item_id)
          hash2[:name] = prod.name
          hash2[:order_od] = o.id
          hash2[:price] = opr.price.to_f.round(2)
          hash2[:pro_num] = opr.pro_num.to_f.round(2)
          hash2[:t_price] = opr.t_price.to_f.round(2)
          hash2[:total_price] = opr.total_price.to_f.round(2)
          prod_detail << hash2
        end if oprs.any?
        hash[:detail] = prod_detail
        orders_now << hash
      end
    rescue
      status = 0
      msg = "数据错误!"
    end
    return [status, msg, order_count, has_pay, orders_now]
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
