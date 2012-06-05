#!/usr/bin/env ruby

#usage: ruby parse.rb user_id game_num

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

File.open("#{DATA_DIR}/#{user_id}_#{game_num}.dat", "r").each_line do |line|
  field2 = line.strip.split("|")[2]
  info = line.strip.split("|")[3]
  id = nil

  if field2.eql?("NODE_MOVED")
    id = info.split(";")[0].split(":")[1].to_i
    data_script += "//node moved\n"
    data_script += "currNodes[#{id}].x=#{info.split(";")[2].split(":")[1]};\n"
    data_script += "currNodes[#{id}].y=#{info.split(";")[3].split(":")[1]};\n"

  elsif field2.eql?("EDGE_CREATED")
    id = info.split(";")[0].split(":")[1].to_i
    a = info.split(";")[2].split(":")[1].to_i
    b = info.split(";")[3].split(":")[1].to_i
    reltype = 1 #default: positive edge
    if id >= 0 && !edge_ids.include?(id)
      edge_ids << id      

      data_script += "//edge created\n"
      data_script += "currEdges[#{id}] = {id:#{id}, a:currNodes[#{a}], b:currNodes[#{b}], reltype:#{reltype}, n:0};\n"
      data_script += "currEdges[\"keys\"].push(#{id});\n"

      matrix_script += "#edge created\n"
      matrix_script += "matrix[#{a}][#{b}][#{reltype}]=true\n"
    end
  elsif field2.eql?("EDGE_DESTROYED")
    id = info.split(";")[0].split(":")[1].to_i
    a = info.split(";")[2].split(":")[1].to_i
    b = info.split(";")[3].split(":")[1].to_i
    reltype = info.split(";")[4].split(":")[1].to_i

    data_script += "//edge destroyed\n"
    data_script += "delete currEdges[#{id}];\n"
    data_script += "currEdges[\"keys\"].splice(currEdges[\"keys\"].indexOf(#{id}),1);\n"

    matrix_script += "#edge destroyed\n"
    matrix_script += "matrix[#{a}][#{b}][#{reltype}]=false\n"

  elsif field2.eql?("EDGE_CHANGED")
    id = info.split(";")[0].split(":")[1].to_i
    a = info.split(";")[2].split(":")[1].to_i
    b = info.split(";")[3].split(":")[1].to_i
    reltype = info.split(";")[4].split(":")[1].to_i
    old_a = info.split(";")[5].split(":")[1].to_i
    old_b = info.split(";")[6].split(":")[1].to_i
    old_reltype = info.split(";")[7].split(":")[1].to_i

    data_script += "//edge changed\n"
    data_script += "currEdges[#{id}] = {id:#{id}, a:currNodes[#{a}], b:currNodes[#{b}], reltype:#{reltype}, n:0};\n"

    matrix_script += "#edge changed\n"
    matrix_script += "matrix[#{old_a}][#{old_b}][#{old_reltype}]=false\n"
    matrix_script += "matrix[#{a}][#{b}][#{reltype}]=true\n"
  end

  if field2.eql?("NODE_MOVED") || field2.eql?("EDGE_CREATED") || field2.eql?("EDGE_DESTROYED") || field2.eql?("EDGE_CHANGED")
    animation_script += clear_graph + reset + data_script + redraw_graph + go_next +"\n"
  end

end


data_script = "//graph sequence of player #{user_id} game #{game_num}\n"+data_script+ "//end sequence\n"
animation_script = "function animateGraph(){\n"+animation_script+"}\n"

File.open("#{GRAPH_DIR}/#{user_id}_#{game_num}_graph.html", "w") {|file| file.puts File.read("#{GRAPH_DIR}/game.html").gsub(/\/\/<!-- #REPLACEGRAPHDATA -->/,data_script).gsub(/\/\/<!-- #REPLACEANIMATIONDATA -->/,animation_script)}

File.open("#{GRAPH_DIR}/#{user_id}_#{game_num}_matrix.txt", "w") {|file| file.puts matrix_script}

puts "Done!"

