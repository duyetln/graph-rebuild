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


#comment out these lines above to use variable 'matrix'
#node_ids = [0, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39]
#matrix={}

#node_ids.each do |a|
#  matrix[a] = {}
#  node_ids.each do |b|
#    matrix[a][b] = {"adjacent"=>false, "reltype"=>-1}
#  end
#end


matrix_script = "
#usage: matrix[a][b]={'adjacent'=>true/false, reltype=>type} where a and b are node ids and integers
#note: this is a directed graph so matrix[a][b] represents a edge from a to b, different from matrix[b][a]
node_ids = [0, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39]
matrix={}
node_ids.each do |a|
  matrix[a] = {}
  node_ids.each do |b|
    matrix[a][b] = {'adjacent'=>false, 'reltype'=>-1}
  end
end

"

script = "//graph sequence of player #{user_id} game #{game_num}\n"

File.open("#{DATA_DIR}/#{user_id}_#{game_num}.dat", "r").each_line do |line|
  field2 = line.strip.split("|")[2]
  info = line.strip.split("|")[3]
  id = nil

  if field2.eql?("NODE_MOVED")
    id = info.split(";")[0].split(":")[1].to_i
    script += "currNodes[#{id}].x=#{info.split(";")[2].split(":")[1]};\n"
    script += "currNodes[#{id}].y=#{info.split(";")[3].split(":")[1]};\n"
  elsif field2.eql?("EDGE_CREATED")
    id = info.split(";")[0].split(":")[1].to_i
    a = info.split(";")[2].split(":")[1].to_i
    b = info.split(";")[3].split(":")[1].to_i
    reltype = 1
    if id.to_i >= 0
      script += "currEdges[#{id}] = {id:#{id}, a:currNodes[#{a}], b:currNodes[#{b}], reltype:#{reltype}, n:0};\n"
      script += "currEdges[\"keys\"].push(#{id});\n"

      #matrix[a][b]["adjacent"]=true
      #matrix[a][b]["reltype"]=reltype
      matrix_script += "matrix[#{a}][#{b}]['adjacent']=true\nmatrix[#{a}][#{b}]['reltype']=#{reltype}\n"
    end
  elsif field2.eql?("EDGE_DESTROYED")
    id = info.split(";")[0].split(":")[1].to_i
    a = info.split(";")[2].split(":")[1].to_i
    b = info.split(";")[3].split(":")[1].to_i
    reltype = -1
    script += "delete currEdges[#{id}];\n"
    script += "currEdges[\"keys\"].splice(currEdges[\"keys\"].indexOf(#{id}),1);\n"
    #matrix[a][b]["adjacent"]=false
    #matrix[a][b]["reltype"]=reltype
    matrix_script += "matrix[#{a}][#{b}]['adjacent']=false\nmatrix[#{a}][#{b}]['reltype']=#{reltype}\n"

  elsif field2.eql?("EDGE_CHANGED")
    id = info.split(";")[0].split(":")[1].to_i
    a = info.split(";")[2].split(":")[1].to_i
    b = info.split(";")[3].split(":")[1].to_i
    reltype = info.split(";")[4].split(":")[1].to_i
    old_a = info.split(";")[5].split(":")[1].to_i
    old_b = info.split(";")[6].split(":")[1].to_i
    old_reltype = info.split(";")[7].split(":")[1].to_i

    script += "currEdges[#{id}] = {id:#{id}, a:currNodes[#{a}], b:currNodes[#{b}], reltype:#{reltype}, n:0};\n"

    #matrix[old_a][old_b]["adjacent"]=false
    #matrix[old_a][old_b]["reltype"]=-1
    matrix_script += "matrix[#{old_a}][#{old_b}]['adjacent']=false\nmatrix[#{old_a}][#{old_b}]['reltype']=-1\n"
    #matrix[a][b]["adjacent"]=true
    #matrix[a][b]["reltype"]=reltype
    matrix_script += "matrix[#{a}][#{b}]['adjacent']=true\nmatrix[#{a}][#{b}]['reltype']=#{reltype}\n"
  end
end

script += "//end sequence\n"

File.open("#{GRAPH_DIR}/#{user_id}_#{game_num}_graph.html", "w") {|file| file.puts File.read("#{GRAPH_DIR}/game.html").gsub(/\/\/<!-- #REPLACEDATAHERE -->/,script)}

File.open("#{GRAPH_DIR}/#{user_id}_#{game_num}_matrix.txt", "w") {|file| file.puts matrix_script}

puts "Done!"

