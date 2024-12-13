require 'graph/cytoscape'
require 'rbbt/rest/web_tool'

module RbbtRESTHelpers

  def user_aesthetics(user)
    aesthetics = []

    aesthetics << ["nodes", "shape", "mapper", "entity_type", {"Gene" => "CIRCLE", "Sample" => "HEXAGON"}]
    #aesthetics << ["nodes", "size", "mapper", "entity_type", {"Gene" => 0.9, "Sample" => 1.3}]
    aesthetics << ["nodes", "borderColor", "mapper", "entity_type", {"Sample" => "#D33682", "Gene" => '#B58900'}]
    aesthetics << ["edges", "directed", "mapper", "database", {"tfacts@genomics" => true }]
    aesthetics << ["edges", "color", "mapper", "database", {"pina@genomics" => "#0000FF", "tfacts@genomics" => "#00FFFF", "undefined" => "#FF00FF", "/sample_genes/" => "#00FFFF" }]
    aesthetics << ["edges", "color", "mapper", "Effect", {"direct" => "#FF0000", "inverse" => '#00FF00'}]

    aesthetics
  end

  def graph(kb_dir = nil, namespace = Organism.default_code("Hsa"), options = {}, &block)
    kb_dir ||= user_kb(user)
    kb = KnowledgeBase === kb_dir ? kb_dir : KnowledgeBase.new(kb_dir, namespace)
    c = Cytoscape.new kb, kb.namespace

    user_aesthetics(user).each do |aesthetic|
      c.add_aesthetic *aesthetic
    end

    c.instance_exec kb, &block
    tool :cytoscape, options.merge(:cytoscape => c)
  end

  def graph_js(kb_dir = nil, namespace = Organism.default_code("Hsa"), options = {}, &block)
    kb_dir ||= user_kb(user)
    kb = KnowledgeBase === kb_dir ? kb_dir : KnowledgeBase.new(kb_dir, namespace)
    c = Cytoscape.new kb, kb.namespace

    user_aesthetics(user).each do |aesthetic|
      c.add_aesthetic *aesthetic
    end

    c.instance_exec kb, &block
    tool :cytoscape_js, options.merge(:cytoscape => c)
  end

  #def graph_d3(kb_dir = nil, namespace = Organism.default_code("Hsa"), options = {}, &block)
  #  kb_dir ||= user_kb(user)
  #  kb = KnowledgeBase === kb_dir ? kb_dir : KnowledgeBase.new(kb_dir, namespace)
  #  c = Cytoscape.new kb, kb.namespace

  #  user_aesthetics(user).each do |aesthetic|
  #    c.add_aesthetic *aesthetic
  #  end

  #  c.instance_exec kb, &block
  #  tool :d3, options.merge(:cytoscape => c)
  #end

end
