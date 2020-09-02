require 'clockwork'
require './config/boot'
require './config/environment'
require 'active_support/time' # Allow numeric durations (eg: 1.minutes)
require './lib/weather_info_job'

module Clockwork
  def schedule(user)
    handler do |job|
      job.call(user)
    end

    # debug用
    # every(60.second, WeatherInfoJob.new, :thread => true)

    every(1.day, WeatherInfoJob.new, :at => user.info_time.strftime("%H:%M"), :thread => true)
  end

  module_function :schedule
end

User.all.each do |user|
  Clockwork.schedule(user)
end
