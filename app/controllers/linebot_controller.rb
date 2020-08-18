class LinebotController < ApplicationController
  require 'line/bot'

  protect_from_forgery except: :callback

  def callback
    body = request.body.read

    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      head :bad_request
    end

    rich_menu =
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
          "action":{
              "type":"message",
              "text":"通知時間を変更"
          }
        }
      ]
    }
    events = client.parse_events_from(body)

    events.each { |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          if event.message['text'].eql?('あ')
            client.reply_message(event['replyToken'], template)
            rich = client.create_rich_menu(rich_menu)
            richmenu_id = JSON.parse(rich.body.gsub('=>', ':'))["richMenuId"]
            client.create_rich_menu_image(richmenu_id, File.open("/Users/sawadakoujirou/line_bot_about_weather/app/image/001.png"))
            client.link_user_rich_menu(event["source"]["userId"], richmenu_id)
            # client.get_rich_menu(richmenu_id)
            # logger.debug("#{client.get_rich_menu(richmenu_id).body}")
          elsif event.message['text'].eql?('位置情報を変更')
            client.reply_message(event['replyToken'], location_image_template)
            client.reply_message(event['replyToken'], location_template)
          end
        when Line::Bot::Event::MessageType::Location
          lat = event.message['latitude'] # 緯度
          lon = event.message['longitude'] # 経度
          client.reply_message(event['replyToken'], template)
        end
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

  def template
    {
      type: 'text',
      text: 'hello'
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

  def line_template
      {
        "events"=>[
          {
            "type"=>"message", "replyToken"=>"8dd6891155bd41c488535119b092c8ff", "source"=>{"userId"=>"U89f27392ac1fbd4f6ee82a93a9c29616", "type"=>"user"},
            "timestamp"=>1597390795082, "mode"=>"active", "message"=>{"type"=>"location", "id"=>"12497729270049", "address"=>"日本、〒060-0063 北海道札幌市中央区南３条西６丁目１−３ ティアラ３６", "latitude"=>43.05577, "longitude"=>141.349891}
          }
        ],
        "destination"=>"U0e2484470e33a7a0e8f9bdb5f769399d",
        "linebot"=>{
          "events"=>[
            {
              "type"=>"message",
              "replyToken"=>"8dd6891155bd41c488535119b092c8ff",
              "source"=>{
                "userId"=>"U89f27392ac1fbd4f6ee82a93a9c29616",
                "type"=>"user"
              },
              "timestamp"=>1597390795082,
              "mode"=>"active",
              "message"=>{
                "type"=>"location",
                "id"=>"12497729270049",
                "address"=>"日本、〒060-0063 北海道札幌市中央区南３条西６丁目１−３ ティアラ３６",
                "latitude"=>43.05577,
                "longitude"=>141.349891
              }
            }
          ],
          "destination"=>"U0e2484470e33a7a0e8f9bdb5f769399d"
        }
      }
  end
end
