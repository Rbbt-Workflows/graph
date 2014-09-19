class RbbtGraph      
  def self.node_info(elem, type, knowledge_base = nil)

    type = type.to_s 
    text = elem.respond_to?(:name) ? elem.name || elem : elem              
    if Annotated === elem
      text = elem.respond_to?(:name) ? elem.name || elem : elem              
      info = elem.info
      info = Misc.add_defaults knowledge_base.entity_options_for(type), info if knowledge_base
      {:label => Annotated.purge(text), :entity_type => type, :info => info, :url => Entity::REST.entity_url(elem) }
    else
      {:label => elem} 
    end
  end

  def self.edge_info(item)
    if AssociationItem === item
      knowledge_base = item.knowledge_base
      {:database => item.database, :info => item.info, :source => item.source, :target => item.target}
    else
      if item =~ /^[\w_]+:.*~.*/
        database, _sep, item = item.partition(":") 
      else
        database = "undefined"
      end

      source, _sep, target = item.partition "~"
      {:source => source, :target => target, :database => database}
    end
  end

  def self.network(associations)
    nodes = {}
    edges = []

    associations.uniq.collect do |item|
      edges << edge_info(item)
      if AssociationItem === item
        knowledge_base = item.knowledge_base
        [item.source_entity, item.target_entity].zip([item.source_entity_type, item.target_entity_type]).each do |elem,type|
          type = type.to_s 
          info = node_info elem, type, knowledge_base
          nodes[Annotated.purge(elem)] = info if info.include? :entity_type or not (nodes.include? elem and nodes[elem].include? :entity_type)
        end
      else
        source, _sep, target = item.partition "~"
        [source, target].each do |elem|
          nodes[elem] = node_info elem, nil unless nodes.include? elem and nodes[elem].include? :entity_type
        end
      end
    end
    {:nodes => nodes, :edges => edges.uniq}
  end
end


