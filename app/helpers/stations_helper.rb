module StationsHelper
  def wo_get_product_name order_id
    pro = OrderProdRelation.joins(:product).select("products.name").where(["order_id=?", order_id]).first
    name = pro.nil? ? nil : pro.name
    return name
  end
end
