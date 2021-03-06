#encoding: utf-8
module RolesHelper
  #权限
  ROLES = {
    #客户
    :customers => {
      :name => "客户管理",
      :show => ["查询",1],
      :create => ["新建客户",2],
      :detail => ["查看客户详细信息", 4],
      :remark => ["备注", 8],
      :send_msg =>["发短信",16],
      :delete => ["删除客户",32],
      :edit => ["编辑客户基本信息",64],
      :edit_car_num => ["编辑车牌信息",128],
      :delete_car_num => ["删除车牌信息",256],
      :revisit => ["客户详情页面回访",512],
      :deal_complaint => ["处理投诉",1024],
      :revisit_search => ["客户回访查询", 2048],
      :revisit_all => ["客户回访", 4096],
      :message_search => ["群发短信查询", 8192],
      :group_msg => ["群发短信",16384]
    },
    #库存
    :materials => {
      :name => "库存管理",
      :add => ["添加物料", 1],
      :in => ["入库",2],
      :out => ["出库",4],
      :dinghuo =>["订货",8],
      :check_all =>["批量盘点",16],
      :make_warning =>["设置库存预警",32],
      :print => ["打印库存清单", 64],
      :mat_search => ["库存查询", 128],
      :mat_mark => ["物料备注", 256],
      :check => ["盘点核实",512],
      :ignore => ["忽略库存预警",1024],
      :ignore_cancel => ["取消忽略出库预警", 2048],
      :rk_search => ["入库记录查询", 4096],
      :ck_search => ["出库记录查询", 8192],
      :dh_search => ["向总部订货记录查询", 16384],
      :sup_dh_serch => ["向供应商订货记录查询", 32768],
      :cuihuo => ["催货",65536],
      :cancel => ["取消订单",131072],
      :pay => ["付款",262144],
      :shouhuo => ["确认收货", 524288],
      :tuihuo => ["退货", 1048576],
      :order_mark => ["订货记录备注",2097152],
      :del_supplier => ["删除供应商",4194304],
      :mat_edit => ["编辑物料", 8388608],
      :delete => ["删除物料", 16777216],
      :add_supplier => ["添加供应商",33554432],
      :supplier => ["查看供应商",67108864],
      :edit_supplier => ["编辑供应商",134217728],
      :material_loss_add => ["添加库存报损",268435456],
      :material_loss_delete => ["删除库存报损",536870912],
      :modify_mat_code => ["修改条形码",1073741824],
      :back_good => ["批量退货", 2147483648],
      :show_sale => ["显示成本价", 2147483648*2]
    },
    #员工管理
    :staffs => {
      :name => "员工管理",
      :add_staff => ["新建员工",1],
      :edit_sys_score => ["编辑系统打分",2],
      :detail_staff => ["查看员工详情",4],
      :add_priase => ["新建奖励",8],
      :add_violation => ["新建违规",16],
      :add_train => ["新建培训",32],
      :month_salary => ["本月工资",64],
      :export_salary => ["导出工资列表",128],
      :edit_salary => ["修改工资",256],
      :detail_salary => ["工资详情",512],
      :edit_show_staff => ["编辑查看员工信息",1024],
      :del_staff =>["删除员工", 2048],
      :manager_score => ["店长打分",4096],
      :del_salary => ["删除工资",8192],
      :deal_violation => ["处理奖励违规",16384],
      :search_staff => ["搜索员工", 32768],
      :phone_inventory => ["手机出库盘点", 65536]
    },
    #统计管理
    :datas => {
      :name => "统计管理",
      :comp_types => ["投诉分类统计", 1],
      :comp_mingxi => ["投诉明细统计", 2],
      :pleased => ["满意度统计", 4],
      :orders => ["客户消费统计", 8],
      :lirun => ["毛利统计", 16],
      :mubiao => ["目标销售额", 32],
      :add_target => ["制定目标销售额", 64],
      :sale => ["活动订单统计", 128],
      :xiaos => ["销售报表", 256],
      :yingye => ["营业额汇总表", 512],
      :svcard => ["储值卡消费记录", 1024],
      :everyday => ["每日销售单据",2048],
      :duiz => ["储值卡对账单",4096],
      :kucun => ["库存订货统计", 8192],
      :jixiao => ["员工绩效统计", 16384],
      :shuip => ["员工平均水平统计", 32768],
      :print => ["打印单据", 65536],
      :chengben => ["成本统计",131072],
      :ruchuku => ["入/出库统计",262144],
      :zhixiao => ["滞销统计",524288],
      :ave_cost_detail => ["平均成本明细统计", 1048576],
      :staff_detail => ["员工成本明细", 1048576*2]
    },
    #现场管理
    :stations => {
      :name => "现场管理",
      :dispatch => ["分配技师",1],
      :video => ["查看现场视频",2]
    },
    #营销管理
    :sales => {
      :name => "营销管理",
      :add_sale => ["添加活动",1],
      :edit_sale => ["修改活动",2],
      :publish => ["发布活动",4],
      :delete => ["删除活动",8],
      :add_product => ["添加产品",16],
      :edit_product => ["编辑产品",32],
      :delete_product => ["删除产品",64],
      :add_service => ["添加服务",128],
      :edit_service => ["编辑服务",256],
      :delete_service => ["删除服务",512],
      :add_p_card => ["添加套餐卡",1024],
      :edit_p_card => ["编辑套餐卡",2048],
      :del_p_card => ["删除套餐卡",4096],
      :show_sale_records => ["查看销售记录",8192],
      :svcard => ["添加优惠卡",16384],
      :edit_svcard => ["修改优惠卡",32768],
      :delete_svcard => ["删除优惠卡",65536],
      :svcard_sale_info => ["优惠卡销售情况",131072],
      :svcard_use_info => ["优惠卡使用情况明细",262144],
      :svcard_use_hz => ["优惠卡使用情况汇总",524288],
      :svcard_leave => ["余额查询",1048576],
      :make_billing => ["开具发票", 2097152]
    },
    #系统设置
    :base_datas => {
      :name => "系统设置",
      :new_station_data => ["新建工位",1],
      :edit_station_data => ["编辑工位",2],
      :del_station_data => ["删除工位",4],
      :roles => ["权限",8],
      :role_conf => ["权限配置",16],
      :role_set => ["用户设定",32],
      :add_role => ["添加角色",64],
      :edit_role => ["编辑角色",128],
      :del_role => ["删除角色",256],
      :role_role_set => ["角色设定",512],
      :edit_store_datas => ["设置门店信息", 1024],
      :edit_limited_pwd =>["设置免单密码",2048]
    },
    #收银管理
    :pay_cash => {
      :name=> "收银管理",
      :can_pay =>["收银",1]
    },
    #财务管理
    :finances => {
      :name=>"财务管理",
      :lookup =>["浏览",1]
    }
  }

  def get_roles_auth_proportion role_ids #获取用户的权限比例
    total_auth_count = 0    #总的权限个数
    ROLES.each do |k, v|
      v.each_with_index do |e, index|
        if index!=0
          total_auth_count += 1
        end
      end
    end

    menus_hash = Menu.all.inject({}){|h, m|h[m.id]=m.controller_name;h}
    rmrs = RoleModelRelation.where(["role_id in (?)", role_ids]).group_by{|e|e.role_id}
    rmrs.each do |k, v|                   #rmrs: {role_id1 : {menu_id1 : nums, menu_id2 : nums,...}, role_id2 : {...}}
      hash = {}
      v.each do |obj|
        hash[obj.menu_id] = obj.num
      end
      rmrs[k] = hash
    end

    r_hash = {}
    rmrs.each do |role_id, auth_hash|
      count = 0     #每个用户所拥有的权限个数
      auth_hash.each do |menu_id, nums|
        con_name = menus_hash[menu_id]
        ROLES[con_name.to_sym].each_with_index do |e, index|
          if index!=0 && (nums&e[1][1]==e[1][1])
            count += 1
          end
        end
      end
      r_hash[role_id] = count.to_f*100/total_auth_count   #每个用户所对应的权限比例
    end
    return r_hash
    #render :json => {:menu => menus_hash, :rmr => rmrs, :count => total_auth_count}
  end


    #是否有权限访问后台
  def has_authority?
    user = Staff.find cookies[:user_id] if cookies[:user_id]
    roles = user.roles if user and Staff::VALID_STATUS.include?(user.status)
    return !roles.blank?
  end

  
  #罗列当前用户的所有权限
  def session_role(user_id)
    user = Staff.includes(:roles => :role_model_relations).find user_id
    roles = user.roles
    user_roles = []
    model_role = {}
    roles.each do |role|
      user_roles << role.id
      model_roles = role.role_model_relations
      model_roles.each do |m|
        model_name = m.model_name
        if model_role[model_name.to_sym]
          model_role[model_name.to_sym] = model_role[model_name.to_sym].to_i|m.num.to_i
        else
          model_role[model_name.to_sym] = m.num.to_i
        end
      end if model_roles
    end if roles
    #    session[:model_role] = model_role
    cookies[:model_role] = {:value => model_role.to_a.join(","), :secure  => true}
    cookies[:user_roles] = {:value => user_roles.join(","), :secure  => true}
  end

end
