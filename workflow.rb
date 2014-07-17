require 'cytoscape'
require 'link'
require 'rbbt/workflow'

Workflow.require_workflow "Genomics"
require 'genomics_kb'

class Graph
  extend Workflow

  input :matches, :tsv, "Match info"
  task :edges  => :yaml do |matches|
    source_type, target_type = matches.key_field
    fields = matches.fields
    matches = matches.to_list unless matches.type == :list
    edges = []
    matches.each do |match, values|
      source, _sep, target = match.partition "~"
      info = Hash[*fields.zip(values).flatten(1)]
      edge = {:source => source, :target => target, :info => info}
      edges << edge
    end
    edges

    nodes
  end

  input :knowledge_base, :string, "Knowledge base code"
  input :databases, :array, "Databases to add", :all
  input :entities, :tsv, "Source entities"
  dep  do |jobname, options|
    entities = options[:entities]
    knowledge_base = Kernel.const_get(options[:knowledge_base])
    jobs  = []
    options[:databases].each do |database|
      matches = knowledge_base.subset(database, entities)
      jobs << Graph.job(:edges, jobname, :matches => matches)
    end
    jobs
  end
  task :network => :yaml do
    edges = deps.inject({}){|acc,e| acc = acc.merge(e)}
    nodes = {}
    entities.each do |type, entities|
    end
  end
end

if __FILE__ == $0

  Graph.task :matrix => :tsv do
    Workflow.require_workflow "Genomics"
    require 'genomics_kb'
    require 'rbbt/entity/study'
    require 'rbbt/entity/study/genotypes'

    STUDY_DIR = "/home/mvazquezg/git/apps/ICGCScout/studies/"

    Study.study_dir = STUDY_DIR

    module Sample
      self.persist :mutations, :annotations
      self.persist :affected_genes, :annotations
    end

    module Study
      self.persist :affected_genes, :annotations
    end

    Study.studies.inject(nil) do |acc,study|
      Log.warn study
      Study.setup(study)
      if study.has_genotypes?

        gene_samples = study.knowledge_base.get_index(:sample_genes2, :source => "Ensembl Gene ID=>Associated Gene Name", :persist => true)
        matches = gene_samples.matches(study.affected_genes.name)

        incidence = AssociationItem.incidence(matches)
        incidence.key_field = "Associated Gene Name"
        incidence.namespace = study.organism

        if acc.nil?
          Log.warn "INIT #{ study }"
          acc = incidence
        else
          Log.error "Attach #{ study }"
          length = acc.fields.length
          incidence.keys.each do |gene|
            acc[gene] ||= [nil] * length
          end
          acc = acc.attach incidence, :fields => incidence.fields
        end
      end

      acc

    end
  end
  matrix = Graph.job(:matrix,nil).run(true).path.tsv :grep => "true.*true"
  matrix.with_unnamed do
    matrix.monitor do
      matrix.through do |k,v| 
        v.replace v.collect{|v| v.nil? ? false : v }
      end
    end
  end


  Graph.task :sample_study => :tsv do

    Workflow.require_workflow "Genomics"
    require 'genomics_kb'
    require 'rbbt/entity/study'
    require 'rbbt/entity/study/genotypes'

    STUDY_DIR = "/home/mvazquezg/git/apps/ICGCScout/studies/"

    Study.study_dir = STUDY_DIR

    module Sample
      self.persist :mutations, :annotations
      self.persist :affected_genes, :annotations
    end

    module Study
      self.persist :affected_genes, :annotations
    end

    sample_study = TSV.setup({}, :key_field => "Sample", :fields => ["Study"], :type => :single)
    Study.studies.each do |study|
      Log.warn study
      Study.setup(study)
      study.samples.select_by(:has_genotype?).each do |sample|
        sample_study[sample] = study
      end
      
    end
    sample_study
  end
  sample_study_job = Graph.job(:sample_study ,nil)
  sample_study_job.run

  require 'rbbt/util/R'
  matrix.R_interactive <<-EOR
library(ggplot2)
library(reshape2)

d = t(rbbt.tsv(file=data_file, stringsAsFactors=TRUE));
colnames(d) <- make.names(colnames(d))
d = (d == "true")

sample_study = rbbt.tsv(file='#{ sample_study_job.path.find }');

d.m = melt(d)

names(d.m) = c("Sample", "Gene", "Value")

  EOR
  
end
