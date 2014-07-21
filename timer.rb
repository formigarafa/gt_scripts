#!/usr/bin/env ruby

require 'time'
timers_file = File.open(File.expand_path('../timers.txt', __FILE__))

parsed_lines = timers_file.each_line.map do |line| 
  key, time_string = line.strip.split(':', 2)
  time = Time.parse(time_string)
  [key, time]
end
timers = Hash[parsed_lines]

timer_up_at = timers.first[1]

timers.each do |name, timer_up_at|
  puts name
  time_left = timer_up_at - Time.now
  minutes_left = (time_left / 60).to_i
  seconds_left = time_left.to_i % 60
  if time_left > 60
    puts "#{minutes_left}:#{seconds_left}"
  else
    puts "Time is up"
    if minutes_left == 0 and (0..59).include? seconds_left
      `say "Time for #{name} is up"`
    end
  end
end