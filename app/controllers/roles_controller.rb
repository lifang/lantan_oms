#encoding: utf-8
class RolesController < ApplicationController #系统设置-权限
  before_filter :has_sign?, :get_title
  def index
    @roles = Role.where(["store_id=?", @store.id])
    @role_auth_hash = get_roles_auth_proportion(@roles.map(&:id))
  end

  def update
    role = Role.find_by_id(params[:id].to_i)
    Role.transaction do
      role_name = params[:role_name]
      if role.update_attribute("name", role_name)
        flash[:notice] = "编辑成功!"
      else
        flash[:notice] = "编辑失败!"
      end
      render :json => nil
    end
  end
  
  def create
    Role.transaction do
      role_name = params[:role_name]
      if Role.create(:name => role_name, :store_id => @store.id, :role_type => Role::ROLE_TYPE[:NORMAL])
        flash[:notice] = "新建成功!"
      else
        flash[:notice] = "新建失败!"
      end
      render :json => nil
    end
  end

  def destroy
    Role.transaction do
      begin
        role = Role.find_by_id(params[:id].to_i)
        RoleModelRelation.delete_all(["role_id=?", role.id])
        RoleMenuRelation.delete_all(["role_id=?", role.id])
        role.destroy
        status = 1
      rescue
        status = 0
      end
      render :json => {:status => status}
    end
  end
  
  def set_auth  #设置权限
    @role = Role.find_by_id(params[:role_id].to_i)
    @menus = Menu.all
    @role_menu_rela = RoleMenuRelation.where(["role_id=? and store_id=?", @role.id, @store.id]).map(&:menu_id)
    rmr = RoleModelRelation.where(["role_id=? and store_id=?", @role.id, @store.id])
    @role_model_rela = rmr.inject({}){|h,rmr|
      h[rmr.menu_id] = rmr.num;
      h
    }
  end

  def set_auth_commit
    role_id = params[:role_id].to_i
    menus = params[:menus]
    roles = params[:roles]
    Role.transaction do
      begin
        RoleMenuRelation.delete_all(["role_id=?", role_id])
        RoleModelRelation.delete_all(["role_id=?", role_id])
        menus.each do |m|
          RoleMenuRelation.create(:role_id => role_id, :menu_id => m.to_i, :store_id => @store.id)
        end if menus && menus.any?
        roles.each do |k, v|
          auth_i = v.inject(0){|i, num| i += num.to_i;i}
          RoleModelRelation.create(:role_id => role_id, :num => auth_i, :menu_id => k.to_i, :store_id => @store.id)
        end if roles && roles.any?
        flash[:notice] = "权限设定成功!"
      rescue
        flash[:notice] = "权限设定失败!"
      end
      redirect_to store_roles_path(@store)
    end
  end

  def role_name_valid   #编辑和创建角色重名验证
    type = params[:type].to_i
    name = params[:role_name]
    status = 0
    if type == 1    #编辑验证
      role_id = params[:role_id].to_i
      role = Role.where(["id!=? and name=? and store_id=?", role_id, name, @store.id]).first
      if role.nil?
        status = 1
      end
    else    #新建验证
      role = Role.find_by_name_and_store_id(name, @store.id)
      if role.nil?
        status = 1
      end
    end
    render :json => {:status => status}
  end


  def get_title
    @title = "权限配置"
  end
end
