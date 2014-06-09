#encoding: utf-8
class ReturnOrder < ActiveRecord::Base
  RETURN_REASON = { 0 => "质量问题", 1 => "服务态度", 2 => "拍错买错",3 => "效果不好，不喜欢",4 => "操作失误", 5 => "其他"}
  
end