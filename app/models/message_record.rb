#encoding: utf-8
class MessageRecord < ActiveRecord::Base
  has_many :send_messages
  belongs_to :store

  STATUS = {:NORMAL => 0, :SENDED => 1,:IGNORE => 2} # 0 未发送 1 已发送 2 已忽略
end
