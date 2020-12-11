require "bunny"
require "matrix"
require "concurrent-ruby"
require "json"

abort("Arg error, read the doc") unless ARGV.size>2

def languages()
    file = File.open "lang.json"
    data = JSON.load file
    file.close
    return data
end

def chunk(file="controller.rb",rate=16)
    buffer = ""
    send = 1
    File.foreach(file) do |line|
        text=buffer+line
        if send%rate==0
            yield(text.upcase!)
            buffer=""
        else
            buffer=text
        end
        send+=1
    end
    yield(buffer.upcase!) unless buffer.size==0
    :ok
end

class Controller
    
    def initialize(file,*port) 

        @frequencies = Vector.zero(26)
        @results = Hash.new
        @totalChar = 0

        @connection = Bunny.new(automatically_recover: false)
        @connection.start
        @inputChannel = @connection.create_channel
        @inQueue = @inputChannel.queue('task_queue', durable: true)
        @outputChannel = @connection.create_channel
        @outQueue = @outputChannel.queue('results',durable: true)

        @myfile = file
        ports=port[0]
        @nbworkers = ports.size
        ports.each do |p|
        system("ruby sender.rb #{p} &") 
        end

        @semaphore1 = Concurrent::Semaphore.new(1000)
        @semaphore2 = Concurrent::Semaphore.new(1000)
        @semaphore3 = Concurrent::Semaphore.new(@nbworkers)

        begin
            @outQueue.subscribe(manual_ack: false, block: false) do |delivery_info, _properties, body|
              message=JSON.parse(body)
              case message["type"]
              when "count"
                @frequencies+=Vector.elements(message["counts"])
                @totalChar+=message["total"]
                @semaphore1.release(1)
              when "compare"
                @results[message["lang"]]=message["similarity"]
                @semaphore2.release(1)
              when "over"
                @semaphore3.release(1)
              else
                puts "message error"
              end
            end
        rescue Interrupt => _
            @connection.close
        end

    end
    
    def workCounters()
        chunk(@myfile) do |x| @inQueue.publish({:instruction=>"count",:data=>x}.to_json, persistent: true) 
            @semaphore1.acquire(1) end
        :done
    end

    def obtainFreq
        @semaphore1.acquire(1000)
        {:freq=>((@frequencies.map do |x| x.to_f end)/(@totalChar)).to_a,:total=>@totalChar}
    end

    def workRegression(freq)
        languages().each do |x,_| @inQueue.publish({:instruction=>"compare",:data=>{:language=>x,:freq=>freq}}.to_json,persistent:true) 
            @semaphore2.acquire(1) end
        :done

    end

    def stopWorkers
        (1..@nbworkers).each do |_| @inQueue.publish({:instruction=>"stop"}.to_json,persistent:true) 
            @semaphore3.acquire(1) end
        :over
    end

    def obtainResults
        @semaphore2.acquire(1000)
        @results.sort_by{|k,v| v}.reverse.to_h
    end

    def endall
        @semaphore3.acquire(@nbworkers)
        @connection.close
    end

end

control = Controller.new(ARGV[0],ARGV[1..-1])
control.workCounters
freq_results = control.obtainFreq
control.workRegression(freq_results[:freq])
reg_results = control.obtainResults
control.stopWorkers
control.endall
puts "FREQUENCY ANALYSIS"
puts "\n"
puts freq_results.to_json
puts "\n"
puts "POSSIBLE LANGUAGES"
puts "\n"
puts reg_results.to_json
puts "\n"
puts "MOST LIKELY"
puts "\n"
puts reg_results.to_a[0]
puts "\n"
