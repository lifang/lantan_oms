#encoding: utf-8
module MonthSalariesHelper
  def get_last_twelve_months
    months = []
    12.times do |i|
      months << DateTime.now.months_ago(i+1).strftime("%Y-%m")
    end
    months
  end
end
