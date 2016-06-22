module VirtFS::Fat32
  module Util
    def rubyToDosTime(tim)
      # Time
      sec = tim.sec; sec -= 1 if sec == 60 #correction for possible leap second.
      sec = (sec / 2).to_i #dos granularity is 2sec.
      min = tim.min; hour = tim.hour
      dos_time = (hour << 11) + (min << 5) + sec
      # Day
      day = tim.day; month = tim.month
      # NOTE: This fails after 2107.
      year = tim.year - 1980 #DOS year epoc is 1980.
      dos_day = (year << 9) + (month << 5) + day
      return dos_time, dos_day
    end
  end # module Util
end # module VirtFS::Fat32
