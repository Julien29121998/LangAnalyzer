require 'httparty'
require "bunny"
require "json"

def require_lang_data(lang)
  file = File.open "lang.json"
  data = JSON.load file
  file.close
  return data[lang]
end

unless ARGV.size == 0 
    connection = Bunny.new(automatically_recover: false)
    connection.start
    inputChannel = connection.create_channel
    inQueue = inputChannel.queue('task_queue', durable: true)
    inputChannel.prefetch(1)
    outputChannel = connection.create_channel
    outQueue = outputChannel.queue('results',durable: true)
    begin
      inQueue.subscribe(manual_ack: true, block: true) do |delivery_info, _properties, body|
          answer = {:type=>"err"}
          message = JSON.parse(body.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?'))
          instruction = message["instruction"]
          data = message["data"]
          case instruction
          when "stop"
            answer = {:type=>"over"}
            outQueue.publish(answer.to_json,persistent:true)
            inputChannel.ack(delivery_info.delivery_tag)
            puts("Task finished, worker dies.")
            exit!            
          when "count"
            res = HTTParty.post("http://172.17.0.1:#{ARGV[0]}/count.php",
              :body=> { :text=> data}.to_json,
              :headers => {'Content-Type' => 'application/json'})
            if(res.code==200)
              result = JSON.parse(res.body) 
              answer = {:type=>"count", :counts =>result["counts"], :total=>result["total"]}
            else
              answer = {:type=>"count", :counts=> Array.new(26,0),:total=>0}
            end
          when "compare"
            lang = data["language"] 
            model = require_lang_data(lang)
            res = HTTParty.post("http://172.17.0.1:#{ARGV[0]}/regression.php",
              :body=> { :dataset=> data["freq"], :model=> model}.to_json,
              :headers => {'Content-Type' => 'application/json'})
            if(res.code==200)
              result = JSON.parse(res.body) 
              puts result
              answer = {:type=>"compare", :lang =>lang, :similarity=>result["r2"]}
            else
              answer = {:type=>"compare", :lang =>lang, :similarity=>0}
            end

          else
            puts "error: bad instruction"
          end
        outQueue.publish(answer.to_json,persistent:true)
        inputChannel.ack(delivery_info.delivery_tag)
      end
    rescue Interrupt => _
      connection.close
    end

end