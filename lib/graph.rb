class RbbtGraph      
  def self.network(associations)
    nodes = {}
    edges = []
    associations.uniq.collect do |item|
      if AssociationItem === item
        knowledge_base = item.knowledge_base
        edges << {:database => item.database, :info => item.info, :source => item.source, :target => item.target}

        [item.source_entity, item.target_entity].zip([item.source_entity_type, item.target_entity_type]).each do |elem,type|
          type = type.to_s 
          text = elem.respond_to?(:name) ? elem.name || elem : elem              
          if Annotated === elem
            text = elem.respond_to?(:name) ? elem.name || elem : elem              
            info = knowledge_base.entity_options_for(type)
            nodes[Annotated.purge(elem)] = {:label => Annotated.purge(text), :entity_type => type, :info => info, :url => Entity::REST.entity_url(elem) }
          else
            nodes[elem] = {:label => elem} unless nodes.include?(elem) and nodes[elem].include? :entity_type
          end
        end
      else
        if item =~ /^[\w_]+:.*~.*/
          database, _sep, item = item.partition(":") 
        else
          database = "undefined"
        end

        source,_sep, target = item.partition("~")
        edges << {:source => source, :target => target, :database => database}
        [source, target].each do |elem|
          nodes[elem] = {:label => elem} unless nodes.include?(elem) and nodes[elem].include? :entity_type
        end
      end
    end
    {:nodes => nodes.collect{|k, info| info.merge(:id => k)}, :edges => edges.uniq}
  end
end


