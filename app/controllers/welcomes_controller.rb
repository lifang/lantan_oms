#encoding: utf-8
class WelcomesController < ApplicationController  #主页
  before_filter :has_sign?
  layout :false
  def index
    @title = "欢迎"
  end
  
end
