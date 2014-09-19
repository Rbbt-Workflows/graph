require 'pqueue'

$scores = {}
$adjacent = {}

def score_match(item)
  case item.database
  when /pina/
    3
  when /tfacts/
    2
  when /miller/
    0.01
  else
    10
  end
end

def score(kb, source, target)
  #$scores[[kb,source, target]]||=begin
  associations = kb.all_databases.inject([]) do |acc,database|
    acc.concat(kb.subset(database, :source => [source], :target => [target]).to_a)
    #acc.concat(kb.subset(database, :target => [source], :source => [target]).to_a) if kb.undirected(database)
    acc
  end
  associations.collect{|a| score_match(a)}.sort.first || nil
  #end
end

def adjacent(kb, entity, coef = 0)
  #$adjacent[[kb,entity]]||=begin
  associations = kb.all_databases.inject([]) do |acc,database|
    neighbours = kb.neighbours(database, entity)
    acc.concat neighbours.values.compact.collect{|l| l.to_a }.flatten
    acc
  end

  if coef and coef > 0
    sorted_annotations = associations.sort_by{|e| 
      s = score_match(e)
      s + coef * rand(s)
    } 
  else
    sorted_annotations = associations.sort_by{|e| score_match(e)} 
  end

  sorted_annotations.collect{|i| 
    entity == i.target ? i.source : i.target
  }.uniq 
  #end
end

def dijkstra(kb, start_node, end_node = nil, threshold = nil, max_steps = nil, coef = nil)
  iii coef
  distances = Hash.new { 1.0 / 0.0 } 

  best = 1.0 / 0.0
  best_path = nil
  found = false
  final_set = Set.new(String === end_node ? [end_node] : end_node)
  node_dist_cache = {}

  bar = Log::ProgressBar.new

  active = PQueue.new([]){|a,b| a[2] <=> b[2]}         
  active << [start_node, [start_node], 0]
  until active.empty?
    bar.tick

    current, path, distance = active.pop

    break if found
    next if distance >= best
    next if max_steps and path.length > max_steps

    next_nodes = adjacent(kb, current) 
    next_nodes.each do |n|
      step_distance = score(kb,current,n)
      next if step_distance.nil?
      next_distance = distance + step_distance
      next if next_distance >= best or (threshold and next_distance > threshold)
      next_path = path + [n]

      if final_set.include? n
        found = true
        if next_distance < best
          best = next_distance
          best_path = next_path
        end
      else
        active << [n, next_path, next_distance]
      end
    end
  end

  return nil unless found
  return best_path 
end

def evidence(kb, path)
  evidence = {}
  current = path.shift
  while path.any?
    n = path.shift
    pair = [current, n]
    evidence[pair] = kb.pair_matches(current, n, true)
    current = n
  end
  evidence
end

def explain(kb, source, target, max_steps = 3, coef = nil)
  Log.info "Finding paths: #{[source, target] * "=>" }"
  if coef.nil? or coef == 0
    paths = dijkstra(kb, source, [target], nil, max_steps)
    return nil if paths.nil?
    paths = [paths]
  else
    paths = []
    10.times do
      path = dijkstra(kb, source, [target], nil, max_steps, coef)
      paths << path unless path.nil?
    end
    paths.uniq!
  end
  Log.info "Finding evidence for: #{Misc.fingerprint paths}"
  path_evidence = {}
  paths.each do |path|
    path_evidence[path] = evidence(kb, path.dup)
  end
  path_evidence
end

