#encoding: utf-8
class StoragesController < ApplicationController #库存管理
  before_filter :has_sign?, :get_title
  def mat_index
    @mat_type = Category.where(["store_id=? and types=?", @store.id, Category::TYPES[:material]])
    @materials = Product.find_by_sql(["select p.*, c.name cname from products p inner join categories c
        on p.category_id=c.id where p.store_id=? and p.status=? and p.types=?", @store.id,
        Product::STATUS[:NORMAL], Product::TYPES[:MATERIAL]])
    @revi_time = [12,24,36,48,60,72,84,96]

  end

  def get_title
    if request.url.include?("storages")
      @title = "库存管理"
    end
  end
end