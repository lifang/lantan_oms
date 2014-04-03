#encoding: utf-8
class CarNum < ActiveRecord::Base
  belongs_to :car_model
  has_one :customer_num_relation
  has_many :orders
  belongs_to :customer
  has_many :reservations

end
