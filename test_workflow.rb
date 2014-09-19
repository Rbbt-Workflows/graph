require 'rbbt/workflow'

Workflow.require_workflow "Graph"

class KnowledgeBase

  def evidence(path)
    current = path.shift
    found = []

    while path.any?
      n = path.shift
      found.concat self.pair_matches(current,n).collect{|i| i.target != n ? i.invert : i }
      current = n
    end

    found
  end

  def traversal(start_list, eend_list, &block)
    matches = []

    all_databases.each do |database|
      neighbours = neighbours(database, start_list).values.collect{|l| l.collect{|i| i }}.flatten
      matches.concat(neighbours)
    end

    sorted_matches = matches.sort_by{|m|  block.call m.source, m.target }

    require 'rbbt/network/paths'
    start_list.inject([]){|acc,start|
      path = AssociationItem.dijkstra(sorted_matches, start, eend_list, nil, 5, &block)

      next acc if path.nil?

      acc << path 

      acc 
    }
  end
end

Workflow.require_workflow "Genomics"
Workflow.require_workflow "Miller"

require 'rbbt/knowledge_base/Miller'
require 'rbbt/knowledge_base/Genomics'

require 'rbbt/entity/gene'
require 'rbbt/entity/Miller'

TmpFile.with_file do |kb_dir|
  kb_dir = '/tmp/test_kb_graph5'
  kb = KnowledgeBase.new kb_dir, Miller.organism
  kb.format = {"Gene" => "Ensembl Gene ID"}

  kb.syndicate :genomics, Genomics.knowledge_base
  kb.syndicate :Miller, Miller.knowledge_base

  inhibited = Miller.drug_targets.tsv(:fields => "Ensembl Gene ID").values.compact.flatten.uniq

  deactivated = Miller.knowledge_base.subset(:compound_protein_changes, :all).target

  counts = Hash.new{1}
  path_evidences = nil

  20.times do |iteration|
    paths = kb.traversal (deactivated + inhibited), deactivated do |source,target|
      name = [source,target].sort * "~"
      ct = counts[target]
      cs = counts[source]
      cn = counts[name]

      (iteration + 1) / Misc.mean([ct, cs, cn])
    end

    matches = []
    path_evidences = paths.inject([]) do |acc,path|
      orig = path * "~"
      found = kb.evidence(path)

      acc << [orig, found]

      acc
    end

    new_evidence = path_evidences.collect{|path,evidences| evidences }.flatten

    id, it, is, inn = 1, 10, 10, 50
    new_evidence.each do |item|
      counts[item.database] += id
      counts[item.target] += it
      counts[item.source] += is
      counts[item.name] += inn
    end
  end


  path_evidences.each{|path,evidence|
    path = evidence.collect{|i| [i.source_entity, i.target_entity]}.flatten.uniq.collect{|e| e.respond_to?(:name)? e.name : e} * " => "
    puts Log.magenta(path)
    puts(evidence.collect{|i| i.name } * ", ")
  }

end

