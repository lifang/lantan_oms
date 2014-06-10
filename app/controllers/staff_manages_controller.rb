#encoding: utf-8
class StaffManagesController < ApplicationController #员工管理-员工列表
  before_filter :has_sign?, :get_title
  require 'will_paginate/array'
  def index
    @name = params[:staff_name]
    @tow = params[:tow]
    @status = params[:status]
    sql = ["select s.*, d1.name pname, d2.name dname from staffs s inner join departments d1 on s.department_id=d1.id
      inner join departments d2 on s.position=d2.id where s.status in (?) and s.store_id=?", Staff::VALID_STATUS, @store.id]
    unless @name.nil? || @name.strip==""
      sql[0] += " and s.name like ?"
      sql << "%#{@name.gsub(/[%_]/){|n|'\\'+n}}%"
    end
    unless @tow.nil? || @tow.to_i==-1
      sql[0] += " and s.type_of_w=?"
      sql << @tow.to_i
    end
    unless @status.nil? || @status.to_i==-1
      sql[0] += " and s.status=?"
      sql << @status.to_i
    end
    sql[0] += " order by s.created_at desc"
    staffs = Staff.find_by_sql(sql)

    @count = staffs.length
    @staffs = staffs.paginate(:per_page => 2, :page => params[:page] ||=1)
    @status_hash = Staff::STATUS_NAME.delete_if{|k, v| k == Staff::STATUS[:resigned] || k == Staff::STATUS[:deleted]}
  end

  def new
    @departs = Department.where(["types=? and store_id=? and status=?", Department::TYPES[:DEPARTMENT], @store.id,
        Department::STATUS[:NORMAL]])
  end

  def create
    img = params[:staff_img]
    if img && img.size > Staff::MAX_SIZE
      flash[:notice] = "用户头像尺寸最大不得超过5MB!"
    else
      is_score_ge_salary = params[:staff_is_score_g_s].nil? || params[:staff_is_score_g_s].to_i!=1 ? false : true
      hash = {
        :name => params[:staff_name], :type_of_w => params[:staff_tow].to_i, :position => params[:staff_dpt].to_i,
        :sex => params[:staff_sex].to_i==1 ? true : false, :level => params[:staff_level].to_i, :birthday => params[:staff_birthday], :id_card => params[:staff_idn],
        :hometown => params[:staff_hometown], :education => params[:staff_education].to_i, :nation => params[:staff_nation], :political => params[:staff_political],
        :phone => params[:staff_phone], :address => params[:staff_addr], :base_salary => params[:staff_base_salary].to_f.round(2), :status => Staff::STATUS[:normal],
        :store_id => @store.id, :username => params[:staff_name], :is_score_ge_salary => is_score_ge_salary, :working_stats => params[:staff_work_st].nil? ? 1 : 0,
        :probation_salary => params[:staff_work_st].nil? ? nil : params[:staff_prob_salary].to_f.round(2),
        :probation_days =>  params[:staff_work_st].nil? ? nil : params[:staff_prob_days].to_f.round(2),
        :is_deduct => params[:staff_is_deduct].nil? || params[:staff_is_deduct].to_i==0 ? false : true, :department_id => params[:staff_posi].to_i,
        :secure_fee => params[:staff_secure_fee].to_f.round(2), :reward_fee => params[:staff_reward_fee].to_f.round(2), :entry_time => params[:staff_entry_time],
        :labor_contract => params[:staff_labor_contract], :remark => params[:staff_remark], :w_days_monthly => params[:staff_w_monthly].to_i
      }
      begin
        Staff.transaction do
          staff = Staff.new(hash)
          staff.password = params[:staff_phone]
          staff.encrypt_password
          staff.save
          if img
            path, msg = Staff.upload_img(img, @store.id, staff.id)
            if path == ""
              flash[:notice] = "新建成功,图片上传失败!"
            else
              flash[:notice] = "新建成功!"
            end
          else
            flash[:notice] = "新建成功!"
          end
        end
      rescue
        flash[:notice] = "新建员工失败!"
      end
    end
    redirect_to "/stores/#{@store.id}/staff_manages"
  end

  #新建奖励或惩罚
  def new_reward_violation
      @staffs = Staff.where(["store_id=? and status in (?)", @store.id, Staff::VALID_STATUS])
      @types = params[:types].to_i #1奖励 0惩罚
  end

  #创建奖励或惩罚
  def create_reward_violation
    @types = params[:types].to_i #1奖励 0惩罚
    staffs = params[:staffs].nil? || params[:staffs].blank? ? nil :  params[:staffs].collect { |s|s.to_i  }
    belong_types = params[:belong_types].to_i
    process_types = params[:process_types].to_i
    situation = params[:situation]
    score_num = params[:score_num].nil? || params[:score_num].strip=="" ? nil : params[:score_num].to_f.round(2)
    salary_num = params[:salary_num].nil? || params[:salary_num].strip=="" ? nil : params[:salary_num].to_f.round(2)
    mark = params[:mark]
    @status = 1
    begin
      ViolationReward.transaction do
        staffs.each do |s|
          ViolationReward.create!(:staff_id => s, :situation => situation, :status => ViolationReward::STATUS[:NOMAL],
          :process_types => process_types, :mark => mark, :types => @types, :score_num => score_num,
          :salary_num => salary_num, :belong_types => belong_types)
        end if staffs
        flash[:notice] = @types == 1 ? "奖励创建成功!" : "处罚创建成功!"
      end
    rescue
      @status = 0
    end
  end

  #新建培训
  def new_train
    @staffs = Staff.where(["store_id=? and status in (?)", @store.id, Staff::VALID_STATUS])
  end
  #创建培训
  def create_train
    s_time = params[:train_s_time]
    e_time = params[:train_e_time]
    staffs = params[:staffs].nil? ||  params[:staffs].blank? ? nil : params[:staffs].collect{|s|s.to_i}
    train_type = params[:train_type].to_i
    has_cert = params[:has_certif].nil? || params[:has_certif].to_i!=1 ? false : true
    cont = params[:train_cont]
    @status = 1
    begin
      Train.transaction do
        train = Train.create!(:content => cont, :start_at => s_time, :end_at => e_time, :certificate => has_cert,
          :train_type => train_type)
        staffs.each do |s|
          TrainStaffRelation.create!(:train_id => train.id, :staff_id => s, :status => false)
        end if staffs
        flash[:notice] = "培训创建成功!"
      end
    rescue
      @status = 0
    end
  end
  #新近员工名称与手机号码验证
  def staff_valid
    types = params[:types].to_i
    name = params[:staff_name]
    phone = params[:staff_phone]
    status = 1
    msg = ""
    if types == 1 #新建时的验证
      staff = Staff.where(["name=? and status in (?) and store_id=?", name, Staff::VALID_STATUS, @store.id]).first
      if staff.nil?
        staff = Staff.where(["phone=? and status in (?) and store_id=?", phone, Staff::VALID_STATUS, @store.id]).first
        if staff
          status = 0
          msg = "该手机号已被注册!"
        end
      else
        status = 0
        msg = "已有同名的员工!"
      end
    elsif types == 2    #编辑时...

    end
    render :json => {:status => status, :msg => msg}
  end

  #查询职位
  def search_posis
    @positions = Department.where(["types=? and dpt_id=? and store_id=? and status=?", Department::TYPES[:POSITION],
        params[:dpt_id].to_i, @store.id, Department::STATUS[:NORMAL]])
  end

  def get_title
    @title = "员工列表"
  end
end