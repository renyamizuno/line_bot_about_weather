class WeatherInfoJob
  require 'line/bot'

  def call(user)
    hash_of_weather_info = get_hash_of_wether_info(user.lat, user.lon)

    return puts "雨降らなさそうなので処理中止！" unless check_if_today_will_rain?(hash_of_weather_info)

    push_message(user, get_percentage_of_max_pop_today(hash_of_weather_info))
  end

  private
  def get_hash_of_wether_info(lat, lon)
    uri = URI.parse("https://api.openweathermap.org/data/2.5/forecast?lat=#{lat}&lon=#{lon}&appid=#{ENV["OPEN_WEATHER_MAP_APP_ID"]}&lang=ja")
    puts uri
    req = Net::HTTP.new(uri.host,uri.port)

    req.use_ssl = true
    req.verify_mode = OpenSSL::SSL::VERIFY_NONE
    # 参考
    # https://brakemanscanner.org/docs/warning_types/ssl_verification_bypass/

    res = req.get(uri.request_uri)
    case res
    when Net::HTTPSuccess
      return hash = JSON.parse(res.body)
    else
      puts "HTTP ERROR: code=#{res.code} message=#{res}"
    end
  end

  def get_percentage_of_max_pop_today(hash)
    # pop -> probability of precipitation(降水確率)
    max_pop = 0

    hash["list"].each do |list|
      if Time.zone.at(list["dt"]).strftime('%Y-%m-%d') == Time.zone.now.strftime('%Y-%m-%d')
        max_pop = list["pop"] if max_pop < list["pop"]
      end
    end

    return max_pop * 100
  end

  def check_if_today_will_rain?(hash)
    hash["list"].each do |list|
      if Time.zone.at(list["dt"]).strftime('%Y-%m-%d') == Time.zone.now.strftime('%Y-%m-%d')
        if list["pop"] >= 0.4
          return true
        end
      end
    end

    return false
  end

  def push_message(user, max_pop)
    client = Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }

    client.push_message(user.line_id, weather_text(user, max_pop))
  end

  def weather_text(user, max_pop)
    {
      "type": "text",
      "text": "今日は雨が降るかもです！最高降水確率：#{max_pop}% あなたの場所：#{user.address}"
    }
  end
end
