
require "json"

langs={
    0=>"English",
    1=>"French",
    2=>"German",
    3=>"Spanish",
    4=>"Portuguese",
    5=>"Esperanto",
    6=>"Italian",
    7=>"Turkish",
    8=>"Swedish",
    9=>"Polish",
    10=>"Dutch",
    11=>"Danish",
    12=>"Icelandic",
    13=>"Finnish",
    14=>"Czech"
}
file = File.open "client/lang.json"
data = JSON.load file
file.close

i=0
count=0
File.foreach("data.l") do |l|
    if(l.chomp=="<tr>")
        #puts "nl"
        i+=1
        count=0
    else
        if(l.chomp[0..3]=="<td>"&&l.chomp[-6]=="%")
            #puts " #{count},#{data[langs[count]]},#{l.chomp[4..-7].to_f/100}"
            data[langs[count]][i]=l.chomp[4..-7].to_f/100
            count+=1
        end
    end
end

puts data
File.write("client/lang.json",data.to_json)
