# https://devcenter.heroku.com/articles/scheduler


namespace :line do
  desc "Herokuでタスク回すよ。This task is called by the Heroku scheduler add-on"
  task :line_in_the_morning => :environment do
    uri = URI.parse("https://api.openweathermap.org/data/2.5/forecast?lat=#{lat}&lon=#{lon}&appid=aa07326426e4d176a58b0929a56f7998&lang=ja")
    logger.debug "----------"
    logger.debug "----------"
    logger.debug "uri -> #{uri}"
    logger.debug "----------"
    logger.debug "----------"
    req = Net::HTTP.new(uri.host,uri.port)
    req.use_ssl = true
    req.verify_mode = OpenSSL::SSL::VERIFY_NONE

    res = req.get(uri.request_uri)
    # logger.debug "#{res.body}"
    case res
    when Net::HTTPSuccess
      hash_of_result = JSON.parse(res.body)
      # logger.debug "----------"
      # logger.debug "----------"
      # logger.debug "@hash_of_result -> #{JSON.pretty_generate(@hash_of_result).gsub(":", " =>")}"
      # logger.debug "----------"
      # logger.debug "----------"
      # @formatted = format_hash(@hash_of_result)
      formatted = format_hash(hash_of_result)
      client.reply_message(event['replyToken'], weather_text(formatted))
    when Net::HTTPRedirection
      logger.debug "Redirection: code=#{res.code} message=#{res.message}"
    else
      logger.debug "HTTP ERROR: code=#{res.code} message=#{res}"
    end
  end

  def format_hash(hash)
    # pop = Probability of precipitation(降水確率)
    max_pop = 0
    bool_of_pop = false

    hash["list"].each do |list|
      if Time.zone.at(list["dt"]).strftime('%Y-%m-%d') == Time.zone.now.strftime('%Y-%m-%d')
        percent = list["pop"] * 100
        if percent > 0.01
          bool_of_pop = true
          max_pop = percent if max_pop < percent
        end
      end
    end

    return {probability: max_pop, bool: bool_of_pop}
  end

  def weather_text(hash)
    {
      "type": "text",
      "text": "今日は雨が降るかもです！降水確率：#{hash[:probability]}%"
    }
  end
end
