#encoding: utf-8
class MessageTemp < ActiveRecord::Base    #短信模板
  belongs_to :store
  
  TYPE = {:appellation => 1, :message => 2, :greeting => 3, :store_name => 4}
  TYPE_NAME = {1 => "常用称呼", 2 => "常用短信", 3 => "节日问候", 4 => "落款门店"}


end
