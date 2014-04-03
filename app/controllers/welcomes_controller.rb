#encoding: utf-8
class WelcomesController < ApplicationController
  before_filter :has_sign?
  layout :false
  def index
    
  end
end
