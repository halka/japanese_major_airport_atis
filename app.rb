# frozen_string_literal: true

require 'sinatra'
require 'dotenv'
require 'line/bot'

$atis = []
def client
  Dotenv.load
  @client ||= Line::Bot::Client.new do |config|
    config.channel_secret = ENV['LINE_CHANNEL_SECRET']
    config.channel_token = ENV['LINE_CHANNEL_TOKEN']
  end
end

def get_atis
  url = URI.parse(ENV['ATIS_URL'])
  res = Net::HTTP.get_response(url)
  halt 403, { 'Content-Type' => 'text/plain' }, 'Bad Request' unless res.code != 200
  $atis = JSON.parse(res.body)
end

post '/callback' do
  body = request.body.read

  signature = request.env['HTTP_X_LINE_SIGNATURE']
  halt 400, { 'Content-Type' => 'text/plain' }, 'Bad Request' unless client.validate_signature(body, signature)
  events = client.parse_events_from(body)

  events.each do |event|
    case event
    when Line::Bot::Event::Message
      case event.type
      when Line::Bot::Event::MessageType::Text
        messages = []
        stations = event.message['text'].upcase.split(/[,|\s+]/, 0).reject(&:empty?)
        get_atis unless stations.length.zero?
        stations.each do |station|
          $atis.each_with_index do |x, i|
            next unless $atis[i]['callsign'] == station

            message = {
              type: 'text',
              text: x['atisdat']
            }
            messages.push(message)
          end
        end
        if messages.empty?
          message = {
            type: 'text',
            text: 'ATIS Not Provided'
          }
          messages.push(message)
        end
        client.reply_message(event['replyToken'], messages)
      end
    end
    'OK'
  end
end
