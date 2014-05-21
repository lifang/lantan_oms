#encoding: utf-8
class SetFunctionsController < ApplicationController  #系统设置-组织架构
  before_filter :has_sign?, :get_title
  def index
    @type = params[:type]
    @store = Store.find_by_id(params[:store_id].to_i)
    @departs = Department.where(["types = ? and store_id = ? and status = ?", Department::TYPES[:DEPARTMENT], #部门
        @store.id, Department::STATUS[:NORMAL]]).order("dpt_lv asc").group_by { |d| d.dpt_lv } if @type.nil? || @type.to_i==0 || @type.to_i==1
    @positions = Department.where(["types = ? and store_id = ? and status = ? and dpt_id is not null",  #职务
        Department::TYPES[:POSITION], @store.id, Department::STATUS[:NORMAL]]).group_by { |p| p.dpt_id } if @type.nil? || @type.to_i==0 || @type.to_i==1
    @storage_goods = Category.where(["types= ? and store_id = ?",  #物料类别
        Category::TYPES[:material], params[:store_id].to_i]) if @type.nil? || @type.to_i==3
    @market_servs = Category.where(["types= ? and store_id = ?", #服务类别
        Category::TYPES[:service], params[:store_id].to_i]) if @type.nil? ||  @type.to_i==4
    respond_to do |f|
      f.html
      f.js
    end
  end

  def create
    @type = params[:type].to_i   #type 0部门 1职务 3物料 4服务
    name = params[:name]
    Store.transaction do
      if @type == 0
        if params[:level].nil?
          lv = Department.find_by_sql(["select max(dpt_lv) max_lv from departments d where d.types=? and d.store_id=?
            and d.status=?",  Department::TYPES[:DEPARTMENT], @store.id, Department::STATUS[:NORMAL]]).first
          Department.create(:name => name, :types => Department::TYPES[:DEPARTMENT],
            :dpt_lv => lv.max_lv.nil? ? 1 : lv.max_lv+1, :store_id => @store.id, :status => Department::STATUS[:NORMAL])
        else
          lv = params[:level].to_i
          Department.create(:name => name, :types => Department::TYPES[:DEPARTMENT],
            :dpt_lv => lv, :store_id => @store.id, :status => Department::STATUS[:NORMAL])
        end
      elsif @type == 3
        Category.create(:name => name, :types => Category::TYPES[:material], :store_id => @store.id)
      elsif @type == 4
        Category.create(:name => name, :types => Category::TYPES[:service], :store_id => @store.id)
      end
      respond_to do |f|
        f.js
      end
    end
  end

  def edit
    @type = params[:type].to_i
    id = params[:id].to_i
    if @type == 0
      @obj = Department.find_by_id(id)
      @positions = Department.where(["types=? and dpt_id=? and store_id=? and status=?", Department::TYPES[:POSITION],
          @obj.id, @store.id, Department::STATUS[:NORMAL]])
    elsif @type == 1

    elsif @type == 2 || @type == 3 || @type == 4
      @obj = Category.find_by_id(id)
    end
  end

  def update
    @type = params[:type].to_i   #type 0部门 1职务 2商品 3物料 4服务
    name = params[:name]
    id = params[:id].to_i
    if @type == 0
      obj = Department.find_by_id(id)
    elsif @type == 1
        
    elsif @type == 2 || @type == 3 || @type == 4
      obj = Category.find_by_id(id)
    end
    Store.transaction do
      if obj.update_attribute("name", name)
        @status = 1
      else
        @status = 0
      end
    end
  end

  def destroy
    type = params[:type].to_i   #type 0部门 1职务 3物料 4服务
    id = params[:id].to_i
    status = 0
    Store.transaction do
      if type == 0 || type == 1
        obj = Department.find_by_id(id)
        if obj.update_attribute("status", Department::STATUS[:DELETED])
          status = 1
        end
      elsif type == 2 || type == 3 || type == 4
        obj = Category.find_by_id(id)
        if obj.delete
          status = 1
        end
      end
      render :json => {:status => status}
    end
  end

  def del_position    #删除职务
    position_id = params[:p_id].to_i
    Department.transaction do
      status = 0
      posotion = Department.find_by_id(position_id)
      if posotion.update_attribute("status", Department::STATUS[:DELETED])
        status = 1
      end
      render :json => {:status => status}
    end
  end

  def edit_position   #编辑职务
    position_id = params[:id].to_i
    name = params[:name]
    Department.transaction do
      status = 0
      posotion = Department.find_by_id(position_id)
      if posotion.update_attribute("name", name)
        status = 1
      end
      render :json => {:status => status}
    end
  end

  def new_position  #新建职务
    name = params[:name]
    dpt_id = params[:dpt_id]
    Department.transaction do
      @status = 0
      position = Department.new(:name => name, :types => Department::TYPES[:POSITION], :dpt_id => dpt_id,
        :store_id => @store.id, :status => Department::STATUS[:NORMAL])
      if position.save
        @status = 1
        @obj = Department.find_by_id(dpt_id)
        @positions = Department.where(["types=? and dpt_id=? and store_id=? and status=?", Department::TYPES[:POSITION],
            @obj.id, @store.id, Department::STATUS[:NORMAL]])
      end      
    end
  end

  def new_valid #新建部门、职务、商品等重名验证
    type = params[:type].to_i   #type 0部门 1职务 2商品 3物料 4服务
    name = params[:name]
    if type == 0
      obj = Department.find_by_name_and_types_and_store_id_and_status(name, Department::TYPES[:DEPARTMENT],
        @store.id, Department::STATUS[:NORMAL])
    elsif type == 1
      dpt_id = params[:dpt_id].to_i
      obj = Department.where(["name=? and types=? and dpt_id=? and store_id=? and status=?", name, Department::TYPES[:POSITION],
          dpt_id, @store.id, Department::STATUS[:NORMAL]]).first
    elsif type == 3
      obj = Category.find_by_name_and_types_and_store_id(name, Category::TYPES[:material], @store.id)
    elsif type == 4
      obj = Category.find_by_name_and_types_and_store_id(name, Category::TYPES[:service], @store.id)
    end
    render :json => {:status => obj.nil? ? 1 : 0}
  end

  def edit_valid #编辑部门、职务、商品等重名验证
    type = params[:type].to_i   #type 0部门 1职务 2商品 3物料 4服务
    name = params[:name]
    id = params[:id].to_i
    if type == 0
      obj = Department.where(["name=? and types=? and store_id=? and status=? and id!=?", name, Department::TYPES[:DEPARTMENT],
          @store.id, Department::STATUS[:NORMAL], id]).first
    elsif type == 1
      dpt_id = params[:dpt_id].to_i
      obj = Department.where(["name=? and types=? and dpt_id=? and store_id=? and status=? and id!=?", name, Department::TYPES[:POSITION],
          dpt_id, @store.id, Department::STATUS[:NORMAL], id]).first
    elsif type == 3
      obj = Category.where(["name=? and types=? and store_id=? and id!=?", name, Category::TYPES[:material],
          @store.id, id]).first
    elsif type == 4
      obj = Category.where(["name=? and types=? and store_id=? and id!=?", name, Category::TYPES[:service],
          @store.id, id]).first
    end
    render :json => {:status => obj.nil? ? 1 : 0}
  end

  def get_title
    @title = "组织架构"
  end
end