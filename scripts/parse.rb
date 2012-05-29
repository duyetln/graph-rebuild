#!/usr/bin/env ruby

ROOT_DIR = File.expand_path(File.expand_path(File.dirname(__FILE__))+"/..")
DATA_DIR = "#{ROOT_DIR}/data"
LOG_DIR = "#{ROOT_DIR}/logs"
SCRIPT_DIR = "#{ROOT_DIR}/scripts"
GRAPH_DIR = "#{ROOT_DIR}/graphs"

user_id = ARGV[0].to_i
game_num = ARGV[1].to_i

(!File.directory?(DATA_DIR) || Dir.entries(DATA_DIR).empty?) && abort("No data")
(!File.directory?(LOG_DIR) || Dir.entries(LOG_DIR).empty?) && abort("No logs")


(!File.file?("#{DATA_DIR}/#{user_id}_#{game_num}.dat")) && abort("Missing #{DATA_DIR}/#{user_id}_#{game_num}.dat")
(!File.file?("#{GRAPH_DIR}/game.html")) && abort("Missing #{GRAPH_DIR}/game.html")

data = {}
data[user_id] = {}
data[user_id][game_num] = {}
data[user_id]["script"] = nil
script = "//graph sequence of player #{user_id} game #{game_num}\n"

File.open("#{DATA_DIR}/#{user_id}_#{game_num}.dat", "r").each_line do |line|
  field2 = line.strip.split("|")[2]
  info = line.strip.split("|")[3]
  id = nil

  if field2.eql?("NODE_MOVED")
    id = info.split(";")[0].split(":")[1]
    script += "currNodes["+id+"].x="+info.split(";")[2].split(":")[1]+";\n"
    script += "currNodes["+id+"].y="+info.split(";")[3].split(":")[1]+";\n"
  elsif field2.eql?("EDGE_CREATED")
    id = info.split(";")[0].split(":")[1]
    if id.to_i >= 0
      script += "currEdges["+id+"] = {id:"+id+", a:currNodes["+info.split(";")[2].split(":")[1]+"], b:currNodes["+info.split(";")[3].split(":")[1]+"], reltype:1, n:0};\n"
      script += "currEdges[\"keys\"].push("+id+");\n"
    end
  elsif field2.eql?("EDGE_DESTROYED")
    id = info.split(";")[0].split(":")[1]
    script += "delete currEdges["+id+"];\n"
    script += "currEdges[\"keys\"].splice(currEdges[\"keys\"].indexOf("+id+"),1);\n"
  elsif field2.eql?("EDGE_CHANGED")
    id = info.split(";")[0].split(":")[1]
    script += "currEdges["+id+"] = {id:"+id+", a:currNodes["+info.split(";")[2].split(":")[1]+"], b:currNodes["+info.split(";")[3].split(":")[1]+"], reltype:"+info.split(";")[4].split(":")[1]+", n:0};\n"
  end
end

script += "//end sequence\n"

File.open("#{GRAPH_DIR}/#{user_id}_#{game_num}_graph.html", "w") {|file| file.puts File.read("#{GRAPH_DIR}/game.html").gsub(/\/\/<!-- #REPLACEDATAHERE -->/,script)}

