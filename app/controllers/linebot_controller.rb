class LinebotController < ApplicationController
  require 'line/bot'

  protect_from_forgery except: :callback

  def callback
    body = request.body.read

    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      head :bad_request
    end

    events = client.parse_events_from(body)
    @user = User.line_id_match(events.first["source"]["userId"])

    events.each { |event|
      begin
        case event
        when Line::Bot::Event::Message
          case event.type
          when Line::Bot::Event::MessageType::Text
            if event.message['text'].eql?('位置情報を変更')
              client.reply_message(event['replyToken'], location_image_template)
            end
          when Line::Bot::Event::MessageType::Location
            line_id = event["source"]["userId"]
            address = event.message['address']
            lat = event.message['latitude']
            lon = event.message['longitude']

            if @user
              @user.update_user_info(address, lat, lon)
            else
              @user = User.create_user(line_id, address, lat, lon)
            end
            client.reply_message(event['replyToken'], update_location_template(@user))
          end
        when Line::Bot::Event::Postback
          selected_time = Time.zone.parse(event["postback"]["params"]["time"])
          if @user.setting_info_time(selected_time)
            client.reply_message(event['replyToken'], success_time_setting_template(@user))
          else
            client.reply_message(event['replyToken'], no_user_template)
          end
        else
          logger.debug("----------")
          logger.debug("----------")
          logger.debug("該当なしです")
          logger.debug("----------")
          logger.debug("----------")
        end
      rescue => e
        logger.debug("----------")
        logger.debug("----------")
        logger.debug("エラーメッセージ：")
        logger.debug(e.message)
        logger.debug("----------")
        logger.debug("----------")
        client.reply_message(event['replyToken'], error_template)
      end
      }

    head :ok
  end

  private
  def client
    client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end

  def new_rich_menu(client, rich_menu, event)
    rich = client.create_rich_menu(rich_menu)
    richmenu_id = JSON.parse(rich.body.gsub('=>', ':'))["richMenuId"]
    client.create_rich_menu_image(richmenu_id, File.open("/Users/sawadakoujirou/line_bot_about_weather/app/image/001.png"))
    client.link_user_rich_menu(event["source"]["userId"], richmenu_id)
    # client.get_rich_menu(richmenu_id)
    # logger.debug("#{client.get_rich_menu(richmenu_id).body}")
  end

  def rich_menu
    {
      "size":{
          "width":1200,
          "height":600
      },
      "selected":false,
      "name":"設定",
      "chatBarText":"設定",
      "areas":[
        {
          "bounds":{
              "x":0,
              "y":0,
              "width":600,
              "height":600
          },
          "action":{
              "type":"message",
              "text":"位置情報を変更"
          }
        },
        {
          "bounds":{
              "x":600,
              "y":0,
              "width":1200,
              "height":600
          },
          "action":
            {
              "type": "datetimepicker",
              "label": "通知の時間帯を設定してね。",
              "data": "data",
              "mode": "time",
            }
        }
      ]
    }
  end

  def update_location_template(user)
    {
      type: 'text',
      text: "位置情報を設定しました。#{user.address}, #{user.lat}, #{user.lon}"
    }
  end

  def location_template
    {
      type: 'text',
      text: 'メニューバーのプラスボタンから位置情報を送信してね。（近所とかで大丈夫です）'
    }
  end

  def location_image_template
    {
      type: 'image',
      originalContentUrl: "https://firebasestorage.googleapis.com/v0/b/hello-react-719e8.appspot.com/o/images%2Fsetting.jpg?alt=media&token=cf77213c-1f8d-4ae6-8f5b-980ae820a092",
      previewImageUrl: "https://firebasestorage.googleapis.com/v0/b/hello-react-719e8.appspot.com/o/images%2Fsetting.jpg?alt=media&token=cf77213c-1f8d-4ae6-8f5b-980ae820a092"
    }
  end

  def success_time_setting_template(user)
    {
      type: 'text',
      text: "設定完了！#{I18n.l user.info_time}に通知が送られるよ！"
    }
  end

  def no_user_template
    {
      type: 'text',
      text: 'ユーザーが設定されてないよ。一回位置情報を送ってね。'
    }
  end

  def error_template
    {
      type: 'text',
      text: 'なんかエラー起きてるので、何回か試してみてダメだったらさわだくんに連絡してね。'
    }
  end
end
