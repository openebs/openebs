  let mockData = [];
  const nodesGenerated = [];
  const nodes = []
  const linskGenerated = [];
  const links = []

  /**
   * Fetch the articles JSON data
   */
  fetch("http://localhost:3000/articles")
  .then(res => res.json())
  .then(data => {
    mockData = data;
    parseGraph();
  })

  function parseGraph() {
    /**
     * Parse the data to generate nodes and links between nodes.
     */
    for (let index = 0; index < mockData.length; index++) {
      const articleData = mockData[index];
  
      // generate node
      if (nodesGenerated.indexOf(articleData.title) < 0) {
        const node = {};
        node.id = articleData.title;
        node.label = articleData.title;
        node.group = 1;
        node.level = 1;
        nodes.push(node);
        nodesGenerated.push(articleData.title);
      }
  
      // generate links
      const link = {};
      link.source = articleData.title;
      articleData.seeAlso.forEach(target => {
        link.target = target;
        link.strength = 0.01;
        if (linskGenerated.indexOf(target + articleData.title) < 0) {
          link.strength *= 2;
        }
        links.push(Object.assign({}, link));
        linskGenerated.push(articleData.title + target);
        if (nodesGenerated.indexOf(target) < 0) {
        const node = {};
        node.id = target;
        node.label = target;
        node.group = 2;
        node.level = 2;
        nodes.push(node);
        nodesGenerated.push(target);
        }
      });
    }
  
    function getNeighbors(node) {
      return links.reduce(function (neighbors, link) {
          if (link.target.id === node.id) {
            neighbors.push(link.source.id)
          } else if (link.source.id === node.id) {
            neighbors.push(link.target.id)
          }
          return neighbors
        },
        [node.id]
      )
    }
    function isNeighborLink(node, link) {
      return link.target.id === node.id || link.source.id === node.id
    }
    function getNodeColor(node, neighbors) {
      if (Array.isArray(neighbors) && neighbors.indexOf(node.id) > -1) {
        return node.level === 1 ? 'blue' : 'green'
      }
      return node.level === 1 ? 'red' : 'gray'
    }
    function getLinkColor(node, link) {
      return isNeighborLink(node, link) ? 'green' : '#E5E5E5'
    }
    function getTextColor(node, neighbors) {
      return Array.isArray(neighbors) && neighbors.indexOf(node.id) > -1 ? 'green' : 'black'
    }
  
    var width = window.innerWidth
    var height = window.innerHeight;
    var svg = d3.select('svg')
    svg.attr('width', width).attr('height', height)
    // simulation setup with all forces
    var linkForce = d3
      .forceLink()
      .id(function (link) { return link.id })
      .strength(function (link) { return link.strength })
    var simulation = d3
      .forceSimulation()
      .force('link', linkForce)
      .force('charge', d3.forceManyBody().strength(-120))
      .force('center', d3.forceCenter(width / 2, height / 2))
    var dragDrop = d3.drag().on('start', function (node) {
      node.fx = node.x
      node.fy = node.y
    }).on('drag', function (node) {
      simulation.alphaTarget(0.7).restart()
      node.fx = d3.event.x
      node.fy = d3.event.y
    }).on('end', function (node) {
      if (!d3.event.active) {
        simulation.alphaTarget(0)
      }
      node.fx = null
      node.fy = null
    })
    function selectNode(selectedNode) {
      var neighbors = getNeighbors(selectedNode)
      // we modify the styles to highlight selected nodes
      nodeElements.attr('fill', function (node) { return getNodeColor(node, neighbors) })
      textElements.attr('fill', function (node) { return getTextColor(node, neighbors) })
      linkElements.attr('stroke', function (link) { return getLinkColor(selectedNode, link) })
    }
    var linkElements = svg.append("g")
      .attr("class", "links")
      .selectAll("line")
      .data(links)
      .enter().append("line")
        .attr("stroke-width", 1)
          .attr("stroke", "rgba(50, 50, 50, 0.2)")
    var nodeElements = svg.append("g")
      .attr("class", "nodes")
      .selectAll("circle")
      .data(nodes)
      .enter().append("circle")
        .attr("r", 10)
        .attr("fill", getNodeColor)
        .call(dragDrop)
        .on('click', selectNode)
    var textElements = svg.append("g")
      .attr("class", "texts")
      .selectAll("text")
      .data(nodes)
      .enter().append("text")
        .text(function (node) { return  node.label })
          .attr("font-size", 15)
          .attr("dx", 15)
        .attr("dy", 4)
    simulation.nodes(nodes).on('tick', () => {
      nodeElements
        .attr('cx', function (node) { return node.x })
        .attr('cy', function (node) { return node.y })
      textElements
        .attr('x', function (node) { return node.x })
        .attr('y', function (node) { return node.y })
      linkElements
        .attr('x1', function (link) { return link.source.x })
        .attr('y1', function (link) { return link.source.y })
        .attr('x2', function (link) { return link.target.x })
        .attr('y2', function (link) { return link.target.y })
    })
    simulation.force("link").links(links)
  }
