#encoding: utf-8
class Capital < ActiveRecord::Base
  has_many :car_brands
  #获取车品牌列表
  def self.get_car_sort
    #车型品牌的选择
    capitals = Capital.all
    brands = CarBrand.all.group_by { |cb| cb.capital_id }
    capital_arr = []
    car_models = CarModel.all.group_by { |cm| cm.car_brand_id  }
    (capitals || []).each do |capital|
      c = capital
      brand_arr = []
      c_brands = brands[capital.id] unless brands.empty? and brands[capital.id]
      (c_brands || []).each do |brand|
        b = brand
        b[:models] = car_models[brand.id] unless car_models.empty? and car_models[brand.id] #brand.car_models
        brand_arr << b
      end
      c[:brands] = brand_arr
      capital_arr << c
    end
    return capital_arr
  end
end
