class LinebotController < ApplicationController
  require 'line/bot'
  protect_from_forgery except: :callback

  before_action :set_value

  def callback
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless @client.validate_signature(@body, signature)
      head :bad_request
    end

    @events.each { |event|
      begin
        case event
        when Line::Bot::Event::Follow
          puts "followイベント走りました。"
          @user = User.create(line_id: event["source"]["userId"])

        when Line::Bot::Event::Unfollow
          puts "unfollowイベント走りました。"
          @user.delete

        when Line::Bot::Event::Postback
          selected_time = Time.zone.parse(event["postback"]["params"]["time"])
          @user.setting_info_time(selected_time)
          @client.reply_message(event['replyToken'], success_time_setting_template(@user))

        when Line::Bot::Event::Message
          case event.type
          when Line::Bot::Event::MessageType::Text
            if event.message['text'].include?('使い方')
              @client.reply_message(event['replyToken'], location_image_template)
            elsif event.message['text'].include?('グッドパッチ')
              @client.reply_message(event['replyToken'], secret_message_template)
            else
              @client.reply_message(event['replyToken'], welcome_message_template)
            end
          when Line::Bot::Event::MessageType::Location
            line_id = event["source"]["userId"]
            address = event.message['address']
            lat = event.message['latitude']
            lon = event.message['longitude']

            @user.update_user_info(address, lat, lon)
            @client.reply_message(event['replyToken'], update_location_template(@user))
          end
        else
          puts "events該当なし"
        end
      rescue => e
        puts e.message
        @client.reply_message(event['replyToken'], error_template)
      end
      }

    head :ok
  end

  private
  def set_value
    @body = request.body.read
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
    @events = @client.parse_events_from(@body)
    @user = User.line_id_match(@events.first["source"]["userId"])
  end

  # デフォルトリッチメニューは一回作ればok
  # def new_rich_menu(client, event)
  #   rich = client.create_rich_menu(rich_menu)
  #   richmenu_id = JSON.parse(rich.body.gsub('=>', ':'))["richMenuId"]
  #   client.create_rich_menu_image(richmenu_id, File.open("/Users/sawadakoujirou/line_bot_about_weather/app/image/001.png"))
  #   client.set_default_rich_menu(richmenu_id)
  # end

  def rich_menu
    {
      "size":{
          "width":1200,
          "height":600
      },
      "selected":true,
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
            "type": "message",
            "text": "使い方を教えて"
          }
        },
        {
          "bounds":{
            "x": 600,
            "y": 0,
            "width": 1200,
            "height": 600
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

  def welcome_message_template
    {
      type: 'text',
      text: "さわだくんの天気予報を追加してくれてありがとう！！\n\nまず最初に位置情報を送ってね！\n(近所とかで大丈夫だよ！)"
    }
  end

  def update_location_template(user)
    {
      type: 'text',
      text: "位置情報を設定しました。\n設定された住所：#{user.address}\n\nここから一番近い場所の天気を伝えるよ"
    }
  end

  def secret_message_template
    {
      type: 'text',
      text: '大損こいた・・・・・・・'
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
      text: "設定完了！\n\n#{I18n.l user.info_time}に通知が送られるよ！"
    }
  end

  def error_template
    {
      type: 'text',
      text: 'なんかエラー起きてるので、何回か試してみてダメだったらさわだくんに連絡してね。'
    }
  end
end
