require 'graph'

class Cytoscape      
  NODE_SCHEMA = [                        
    {:name => :entity_type, :type => :string},      
    {:name => :label, :type => :string},          
    {:name => :url, :type => :string},     
    {:name => :opacity, :type => :number},   
    {:name => :borderWidth, :type => :number},    
    {:name => :borderColor, :type => :string},    
    {:name => :size, :type => :number},                     
    {:name => :selected, :type => :boolean, :defValue => false},   
    {:name => :color, :type => :string},                 
    {:name => :shape, :type => :string},                      
    {:name => :info, :type => :object},                                     
  ]      

  EDGE_SCHEMA = [                       
    {:name => :database, :type => :string},                                
    {:name => :info, :type => :object},                   
    {:name => :opacity, :type => :number},           
    {:name => :color, :type => :string},                 
    {:name => :width, :type => :number},                         
    {:name => :weight, :type => :number},                     
  ]                        

  attr_accessor :knowledge_base, :namespace, :entities, :aesthetics, :associations

  def initialize(knowledge_base, namespace = nil)                
    if namespace and namespace != knowledge_base.namespace                        
      @knowledge_base = knowledge_base.version(namespace)                    
    else                                        
      @knowledge_base = knowledge_base                                
    end                                                       

    @entities = IndiferentHash.setup({})                                         
    @aesthetics = IndiferentHash.setup({})
    @namespace = namespace                                  
  end                                 

  def namespace=(namespace)
    @knowledge_base = @knowledge_base.version(namespace) if @knowledge_base.namespace != namespace
    @namespace = namespace
  end

  def add_associations(associations)
    @associations ||= []
    @associations.concat associations.collect{|i| i }
    @associations.uniq
    if AssociationItem === associations
      add_entities associations.target, associations.target_entity_type
      add_entities associations.source, associations.source_entity_type
    end
  end

  def add_entities(entities, type = nil)                                                   
    type = entities.base_entity.to_s if type.nil? and AnnotatedArray === entities
    raise "No type specified and entities are not Annotated, so could not guess" if type.nil? 
    good_entities = knowledge_base.translate(entities, type).compact.uniq  
    @namespace ||= entities.organism if entities.respond_to? :organism       
    @entities[type] ||= []              
    @entities[type].concat good_entities                  
  end                        

  def add_aesthetic(elem, aesthetic, type, feature, map)
    @aesthetics[elem] ||= {}
    @aesthetics[elem][aesthetic] ||= []
    @aesthetics[elem][aesthetic].push(:type => type, :feature => feature, :map => map)
  end

  #{{{ Network                         

  def self.network(associations)
    {:dataSchema => {:nodes => NODE_SCHEMA, :edges => EDGE_SCHEMA}, :data => RbbtGraph.network(associations)}
  end

  def network
    @associations ||= begin
                        knowledge_base.all_databases.collect do |database|
                          knowledge_base.subset(database, entities).collect{|i| i }
                        end.flatten.compact.uniq
                      end
    Cytoscape.network(@associations)
  end
end


