#encoding: utf-8
module AttendancesHelper
  def get_twelve_months
    months = []
    12.times do |i|
      months << DateTime.now.months_ago(i).strftime("%Y-%m")
    end
    months
  end
end

