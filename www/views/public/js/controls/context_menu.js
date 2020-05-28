function cytoscape_context_menu(tool){
  tool.cytoscape_tool('add_context_menu_item', "Select first neighbors", "nodes", function (evt) {
    var vis = tool.cytoscape_tool('vis');
    var rootNode = evt.target;
    var fNeighbors = vis.firstNeighbors([rootNode]);
    var neighborNodes = fNeighbors.neighbors;
    vis.select([rootNode]).select(neighborNodes);
  });

  tool.cytoscape_tool('add_context_menu_item', "Remove", "nodes", function (evt) {
    var vis = tool.cytoscape_tool('vis');
    var node = evt.target;
    tool.cytoscape_tool('remove_entities', node.data.entity_type, [node.data.id])
    tool.cytoscape_tool('draw');
  });

  tool.cytoscape_tool('add_context_menu_item', "Remove selected", "none", function (evt) {
    var vis = tool.cytoscape_tool('vis');
    var removed_nodes = vis.selected('nodes')
    $.map(removed_nodes, function(node){
      tool.cytoscape_tool('remove_entities', node.data.entity_type, [node.data.id])
    })
    tool.cytoscape_tool('draw');
  });

  tool.cytoscape_tool('add_context_menu_item', "Save SVG", "none", function (evt) {
    var svg = tool.cytoscape_tool('svg', 1000, 1000);
  });

  tool.cytoscape_tool('add_context_menu_item', "Remove leafs", "none", function (evt) {
    var vis = tool.cytoscape_tool('vis');
    var nodes = vis.nodes();
    var edges = vis.edges();

    var removed_nodes = [];
    var node_counts = {};

    $.each(nodes, function(i,n){
      node_counts[n.data.id] = 0
    })
    
    $.each(edges, function(i,e){
      if (node_counts[e.data.target] === undefined) node_counts[e.data.target] = 0
      if (node_counts[e.data.source] === undefined) node_counts[e.data.source] = 0
      node_counts[e.data.target] = node_counts[e.data.target] + 1
      node_counts[e.data.source] = node_counts[e.data.source] + 1
    })
    for (node in node_counts){
      if (node_counts[node] < 2){
        removed_nodes.push(node)
      }
    }

    $.map(removed_nodes, function(node){
      var entity_type = undefined;
      $.each(nodes, function(i,n){ if (n.data.id == node) entity_type = n.data.entity_type})
      tool.cytoscape_tool('remove_entities', entity_type, [node])
    })
    tool.cytoscape_tool('draw');
  });

  tool.cytoscape_tool('add_context_menu_item', "Log info", "nodes", function (evt) {
    var vis = tool.cytoscape_tool('vis');
    var node = evt.target;

    console.log("Node: " + node.data.label);
    for (var i in node.data) {
      var variable_name = i;
      var variable_value = node.data[i];
      if (variable_name == info){
       for (var j in variable_value) {
        var info_variable_name = i;
        var info_variable_value = node.data[i];
        console.log( "  event.target.data.info" + info_variable_name + " = " + info_variable_value );
       }
      }else{
       console.log( "event.target.data." + variable_name + " = " + variable_value );
      }
    }

  });


}
