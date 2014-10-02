require 'rbbt/rest/knowledge_base'
require 'rbbt/rest/web_tool'
require 'helpers/graph'

Workflow.require_workflow "Genomics"
require 'genomics_kb'

include Sinatra::RbbtToolHelper

Rbbt.claim Rbbt.www.views.public.js.cytoscape.find(:lib), :proc do |dir|
  url = "http://cytoscapeweb.cytoscape.org/file/lib/cytoscapeweb_v1.0.3.zip"
  TmpFile.with_file(nil, true, :extension => 'zip') do |zip_file|
    Open.write(zip_file, Open.read(url, :mode => 'rb', :noz => true), :mode => 'wb')
    TmpFile.with_file do |unzip_dir|
      FileUtils.mkdir_p unzip_dir unless File.exists? unzip_dir
      CMD.cmd("unzip -x '#{zip_file}' -d '#{unzip_dir}'")
      FileUtils.mkdir_p dir unless File.exists? dir
      Dir.glob(File.join(unzip_dir, '*')).each do |file|
        FileUtils.mv(file, dir)
      end
    end
  end
  nil
end

Rbbt.www.views.public.js.cytoscape.find(:lib).produce

post '/knowledge_base/network' do
  knowledge_base = consume_parameter :knowledge_base

  namespace = consume_parameter :namespace

  knowledge_base = get_knowledge_base(knowledge_base, namespace)

  databases = consume_parameter(:databases) || consume_parameter(:database)
  databases = databases.nil? ? knowledge_base.all_databases : databases.split("|")

  entities = consume_parameter :entities
  entities = JSON.parse(entities)

  subset = {}
  matches = []
  databases.each do |database|
    items = knowledge_base.subset(database, entities).to_a
    matches.concat(items)
  end

  network = Cytoscape.network(matches)
  content_type "application/json"
  halt 200, network.to_json
end

get '/explain' do
  template_render('explain', @clean_params, "Explain", :cache_type => :sync)
end

get '/associations' do
  template_render('associations', @clean_params, "Explain", :cache_type => :sync)
end

get '/test' do
  template_render('test', @clean_params, "Explain", :cache_type => :sync)
end

Workflow.require_workflow "Genomics"
KnowledgeBaseRESTHelpers.add_syndication :genomics, Genomics.knowledge_base
