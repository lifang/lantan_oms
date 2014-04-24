#encoding: utf-8
class SetStaffsController < ApplicationController  #系统设置-用户设定
  before_filter :has_sign?, :get_title
  require "will_paginate/array"

  def index
    @name = params[:staff_name]
    str = ["store_id=?", @store.id]
    if @name.nil? == false && @name.strip != ""
      str[0] += " and name like ?"
      str << "%#{@name.strip.gsub(/[%_]/){|e|'\\'+e}}%"
    end
    @staffs = Staff.valid.where(str)
      .paginate(:page => params[:page] || 1, :per_page => 2) #Staff::PerPage
    @roles = StaffRoleRelation.joins(:role).select("staff_role_relations.staff_id, roles.name")
      .where(:staff_id => @staffs.map(&:id)).group_by{|e|e.staff_id}
  end

  def edit
    @staff = Staff.find_by_id(params[:id].to_i)
    @staff_roles = StaffRoleRelation.where(:staff_id => @staff.id).map(&:role_id)
    @roles = Role.where(:store_id => @store.id)
  end

  def update
    @staff_id = params[:id]
    roles = params[:roles]
    Staff.transaction do
      begin
        StaffRoleRelation.delete_all(["staff_id=?", @staff_id.to_i])
        roles.each do |role|
          StaffRoleRelation.create(:role_id => role.to_i, :staff_id => @staff_id.to_i)
        end if roles.any?
        @role_names = Role.where(["id in (?)", roles]).map(&:name).join(",") if roles.any?
        @staus = 1
      rescue
        @staus = 0
      end
    end
  end
  
  def get_title
    @title = "用户设定"
  end
end