#!/usr/bin/env ruby

require 'date'

#usage: ruby parse.rb user_id game_num

ROOT_DIR = File.expand_path(File.expand_path(File.dirname(__FILE__))+"/..")
DATA_DIR = "#{ROOT_DIR}/data"
LOG_DIR = "#{ROOT_DIR}/logs"
SCRIPT_DIR = "#{ROOT_DIR}/scripts"
GRAPH_DIR = "#{ROOT_DIR}/graphs"

user_id = ARGV[0].to_i
game_num = ARGV[1].to_i

interval = ARGV[2].to_i
speed = ARGV[3].to_i

(!File.directory?(DATA_DIR) || Dir.entries(DATA_DIR).empty?) && abort("No data")
(!File.directory?(LOG_DIR) || Dir.entries(LOG_DIR).empty?) && abort("No logs")

(!File.file?("#{DATA_DIR}/#{user_id}_#{game_num}.dat")) && abort("Missing #{DATA_DIR}/#{user_id}_#{game_num}.dat")
(!File.file?("#{GRAPH_DIR}/game.html")) && abort("Missing #{GRAPH_DIR}/game.html")

puts "Generating graphs and matrix for user #{user_id} game #{game_num}"


#matrix script - a sequence of ruby code to build an adjacency matrix
matrix_script = "#player: #{user_id} - game: #{game_num}
#usage: matrix[a][b]={0=>true/false,1=>true/false} where a and b are node ids and integers
#0 or 1 is the reltype (1 is positive and 0 is negative)
#note: this is a directed graph so matrix[a][b] represents a edge from a to b, different from matrix[b][a]
node_ids = [0, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39]
matrix={}
node_ids.each do |a|
  matrix[a] = {}
  node_ids.each do |b|
    matrix[a][b] = {0=>false,1=>false}
  end
end

"


#data script - a sequence of nodes and edges reconstruction to load at game initialization
data_script = ""


#animation script - a function to run to animate the whole graph building process
animation_script = ""
clear_graph = "clearGraph();\n"
redraw_graph = "redrawGraph();\n"
go_next = "next();\n"
reset = "resetData();\n"


#ids of unique edges created; it's common that the same edge is created twice
edge_ids = []


#other variables
start = nil #when "GAME_INITIALIZED" starts
last = nil  #the last event in game, regardless of what type
warning = ""


File.open("#{DATA_DIR}/#{user_id}_#{game_num}.dat", "r").each_line do |line|
  time_stamp = line.strip.split("|")[0]
  event = line.strip.split("|")[2]
  info = line.strip.split("|")[3]

  data_code = ""
  matrix_code = ""
  animation_code = ""

  now = DateTime.strptime(time_stamp,'%Y%m%d%H%M%S%L')
  last = now

  id = nil

  if event.eql?("NODE_MOVED")
    id = info.split(";")[0].split(":")[1].to_i
    data_code += "//node moved\n"
    data_code += "currNodes[#{id}].x=#{info.split(";")[2].split(":")[1]};\n"
    data_code += "currNodes[#{id}].y=#{info.split(";")[3].split(":")[1]};\n"

    animation_code += "if (time >= "+((now-start)*24*60*60*1000).to_i.to_s+"){\n"
    animation_code += data_code+"}\n"

  elsif event.eql?("EDGE_CREATED")
    id = info.split(";")[0].split(":")[1].to_i
    a = info.split(";")[2].split(":")[1].to_i
    b = info.split(";")[3].split(":")[1].to_i
    reltype = 1 #default: positive edge
    if id >= 0 && !edge_ids.include?(id)
      edge_ids << id      

      data_code += "//edge created\n"
      data_code += "currEdges[#{id}] = {id:#{id}, a:currNodes[#{a}], b:currNodes[#{b}], reltype:#{reltype}, n:0};\n"
      data_code += "currEdges[\"keys\"].push(#{id});\n"

      matrix_code += "#edge created\n"
      matrix_code += "matrix[#{a}][#{b}][#{reltype}]=true\n"

      animation_code += "if (time >= "+((now-start)*24*60*60*1000).to_i.to_s+"){\n"
      animation_code += data_code+"}\n"

    end

  elsif event.eql?("EDGE_DESTROYED")
    id = info.split(";")[0].split(":")[1].to_i
    a = info.split(";")[2].split(":")[1].to_i
    b = info.split(";")[3].split(":")[1].to_i
    reltype = info.split(";")[4].split(":")[1].to_i

    puts "WARNING: edge #{id} is destroyed before created" && warning += "WARNING: edge #{id} is destroyed before created" unless edge_ids.include?(id)

    data_code += "//edge destroyed\n"
    data_code += "delete currEdges[#{id}];\n"
    data_code += "currEdges[\"keys\"].splice(currEdges[\"keys\"].indexOf(#{id}),1);\n"

    matrix_code += "#edge destroyed\n"
    matrix_code += "matrix[#{a}][#{b}][#{reltype}]=false\n"

    animation_code += "if (time >= "+((now-start)*24*60*60*1000).to_i.to_s+"){\n"
    animation_code += data_code+"}\n"

  elsif event.eql?("EDGE_CHANGED")
    id = info.split(";")[0].split(":")[1].to_i
    a = info.split(";")[2].split(":")[1].to_i
    b = info.split(";")[3].split(":")[1].to_i
    reltype = info.split(";")[4].split(":")[1].to_i
    old_a = info.split(";")[5].split(":")[1].to_i
    old_b = info.split(";")[6].split(":")[1].to_i
    old_reltype = info.split(";")[7].split(":")[1].to_i

    puts "WARNING: edge #{id} is changed before created" && warning += "WARNING: edge #{id} is changed before created" unless edge_ids.include?(id)

    data_code += "//edge changed\n"
    data_code += "currEdges[#{id}] = {id:#{id}, a:currNodes[#{a}], b:currNodes[#{b}], reltype:#{reltype}, n:0};\n"

    matrix_code += "#edge changed\n"
    matrix_code += "matrix[#{old_a}][#{old_b}][#{old_reltype}]=false\n"
    matrix_code += "matrix[#{a}][#{b}][#{reltype}]=true\n"

    animation_code += "if (time >= "+((now-start)*24*60*60*1000).to_i.to_s+"){\n"
    animation_code += data_code+"}\n"

  elsif event.eql?("GAME_INITIALIZED")
    start ||= now
  end

  data_script += data_code
  matrix_script += matrix_code
  animation_script += animation_code
end

data_script = "//graph sequence of player #{user_id} game #{game_num}\n//#{warning}\n"+data_script+"//end sequence\n"

matrix_script = "##{warning}\n"+matrix_script

animation_script = "
//#{warning}

var time = 0;
var interval = #{interval};
var stop = false;

function animateGraph(){
"+clear_graph+reset+"
"+animation_script+"
"+redraw_graph+"time+=#{speed};

if (time >= "+((last-start)*24*60*60*1000).to_i.to_s+"){
//last - stop the animation
stop = true;
alert('Animation ends');
}
}
"

File.open("#{GRAPH_DIR}/#{user_id}_#{game_num}_graph.html", "w") {|file| file.puts File.read("#{GRAPH_DIR}/game.html").gsub(/\/\/<!-- #REPLACEGRAPHDATA -->/,data_script).gsub(/\/\/<!-- #REPLACEANIMATIONDATA -->/,animation_script)}

File.open("#{GRAPH_DIR}/#{user_id}_#{game_num}_matrix.txt", "w") {|file| file.puts matrix_script}

puts "Done!"

