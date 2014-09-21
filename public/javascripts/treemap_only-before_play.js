(function() { 
 d3.select("#monthlies").append("p").text("YAY!");
})();



// var editor = ace.edit("editor");
// editor.setTheme("ace/theme/monokai");

$(function() {
  $( ".resizable" ).resizable();
});
$(function() {
  $( ".draggable" ).draggable();
 });

// BEGIN Treemap code

(function() {

var margin = {top: 20, right: 0, bottom: 0, left: 0},
    width = 1550,
    height = 750 - margin.top - margin.bottom,
    formatNumber = d3.format(",d"),
    transitioning;

var x = d3.scale.linear()
    .domain([0, width])
    .range([0, width]);

var y = d3.scale.linear()
    .domain([0, height])
    .range([0, height]);

var treemap = d3.layout.treemap()
    .children(function(d, depth) { return depth ? null : d._children; })
    .sort(function(a, b) { return a.value - b.value; })
    .ratio(height / width * 0.5 * (1 + Math.sqrt(5)))
    .round(false);

var svg = d3.select("#chart2").append("svg")
    .attr("width", width + margin.left + margin.right)
    .attr("height", height + margin.bottom + margin.top)
    .style("margin-left", -margin.left + "px")
    .style("margin.right", -margin.right + "px")
  .append("g")
    .attr("transform", "translate(" + margin.left + "," + margin.top + ")")
    .style("shape-rendering", "crispEdges");

var grandparent = svg.append("g")
    .attr("class", "grandparent");

grandparent.append("rect")
    .attr("y", -margin.top)
    .attr("width", width)
    .attr("height", margin.top);

grandparent.append("text")
    .attr("x", 6)
    .attr("y", 6 - margin.top)
    .attr("dy", ".75em");

d3.json('/d3/treemap2', function(root) {
  initialize(root);
  accumulate(root);
  layout(root);
  display(root);

  function initialize(root) {
    root.x = root.y = 0;
    root.dx = width;
    root.dy = height;
    root.depth = 0;
  }

  // Aggregate the values for internal nodes. This is normally done by the
  // treemap layout, but not here because of our custom implementation.
  // We also take a snapshot of the original children (_children) to avoid
  // the children being overwritten when when layout is computed.
  function accumulate(d) {
    return (d._children = d.children)
        ? d.value = d.children.reduce(function(p, v) { return p + accumulate(v); }, 0)
        : d.value;
  }

  // Compute the treemap layout recursively such that each group of siblings
  // uses the same size (1×1) rather than the dimensions of the parent cell.
  // This optimizes the layout for the current zoom state. Note that a wrapper
  // object is created for the parent node for each group of siblings so that
  // the parent’s dimensions are not discarded as we recurse. Since each group
  // of sibling was laid out in 1×1, we must rescale to fit using absolute
  // coordinates. This lets us use a viewport to zoom.
  function layout(d) {
    if (d._children) {
      treemap.nodes({_children: d._children});
      d._children.forEach(function(c) {
        c.x = d.x + c.x * d.dx;
        c.y = d.y + c.y * d.dy;
        c.dx *= d.dx;
        c.dy *= d.dy;
        c.parent = d;
        layout(c);
      });
    }
  }

  function display(d) {
    grandparent
        .datum(d.parent)
        .on("click", transition)
      .select("text")
        .text(name(d));

    var g1 = svg.insert("g", ".grandparent")
        .datum(d)
        .attr("class", "depth");

    var g = g1.selectAll("g")
        .data(d._children)
      .enter().append("g");

    g.filter(function(d) { return d._children; })
        .classed("children", true)
        .on("click", transition);

    g.selectAll(".child")
        .data(function(d) { return d._children || [d]; })
      .enter().append("rect")
        .attr("class", "child")
        .call(rect);

    g.append("rect")
        .attr("class", "parent")
        .call(rect)
      .append("title")
        .text(function(d) { return formatNumber(d.value); });

    g.append("text")
        .attr("dy", ".75em")
        .text(function(d) { return d.name; })
        .call(text);

    function transition(d) {
      if (transitioning || !d) return;
      transitioning = true;

      var g2 = display(d),
          t1 = g1.transition().duration(750),
          t2 = g2.transition().duration(750);

      // Update the domain only after entering new elements.
      x.domain([d.x, d.x + d.dx]);
      y.domain([d.y, d.y + d.dy]);

      // Enable anti-aliasing during the transition.
      svg.style("shape-rendering", null);

      // Draw child nodes on top of parent nodes.
      svg.selectAll(".depth").sort(function(a, b) { return a.depth - b.depth; });

      // Fade-in entering text.
      g2.selectAll("text").style("fill-opacity", 0);

      // Transition to the new view.
      t1.selectAll("text").call(text).style("fill-opacity", 0);
      t2.selectAll("text").call(text).style("fill-opacity", 1);
      t1.selectAll("rect").call(rect);
      t2.selectAll("rect").call(rect);

      // Remove the old node when the transition is finished.
      t1.remove().each("end", function() {
        svg.style("shape-rendering", "crispEdges");
        transitioning = false;
      });
    }

    return g;
  }

  function text(text) {
    text.attr("x", function(d) { return x(d.x) + 6; })
        .attr("y", function(d) { return y(d.y) + 6; });
  }

  function rect(rect) {
    rect.attr("x", function(d) { return x(d.x); })
        .attr("y", function(d) { return y(d.y); })
        .attr("width", function(d) { return x(d.x + d.dx) - x(d.x); })
        .attr("height", function(d) { return y(d.y + d.dy) - y(d.y); });
  }

  function name(d) {
    return d.parent
        ? name(d.parent) + "." + d.name
        : d.name;
  }
});

})();

// END Treemap code


// BEGIN Area Chart code (with categories)

(function() {
var margin = {top: 20, right: 55, bottom: 30, left: 40},
    width  = 900 - margin.left - margin.right,
    height = 160  - margin.top  - margin.bottom;

var x = d3.scale.ordinal()
    .rangeRoundBands([0, width], .1);

var y = d3.scale.linear()
    .rangeRound([height, 0]);

var xAxis = d3.svg.axis()
    .scale(x)
    .orient("bottom");

var yAxis = d3.svg.axis()
    .scale(y)
    .orient("left");

var stack = d3.layout.stack()
    .offset("zero")
    .values(function (d) { return d.values; })
    .x(function (d) { return x(d.label) + x.rangeBand() / 2; })
    .y(function (d) { return d.value; });

var area = d3.svg.area()
    .interpolate("linear")
    .x(function (d) { return x(d.label) + x.rangeBand() / 2; })
    .y0(function (d) { return y(d.y0); })
    .y1(function (d) { return y(d.y0 + d.y); });

var color = d3.scale.ordinal()
    .range(["#f92672","#a6e22e","#66d9ef","#fd971f","#ae81ff"]);

var svg = d3.select("#area").append("svg")
    .attr("width",  width  + margin.left + margin.right)
    .attr("height", height + margin.top  + margin.bottom)
  .append("g")
    .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

d3.json("/d3/area_chart", function (error, data) {

  var labelVar = 'date';
  var varNames = d3.keys(data[0])
      .filter(function (key) { return key !== labelVar;});
  color.domain(varNames);

  var seriesArr = [], series = {};
  varNames.forEach(function (name) {
    series[name] = {name: name, values:[]};
    seriesArr.push(series[name]);
  });

  data.forEach(function (d) {
    varNames.map(function (name) {
      series[name].values.push({name: name, label: d[labelVar], value: +d[name]});
    });
  });

  x.domain(data.map(function (d) { return d.date; }));

  stack(seriesArr);

  y.domain([0, d3.max(seriesArr, function (c) { 
      return d3.max(c.values, function (d) { return d.y0 + d.y; });
    })]);

/*  svg.append("g")
      .attr("class", "x axis")
      .attr("transform", "translate(0," + height + ")")
      .call(xAxis);*/

  svg.append("g")
      .attr("class", "y axis")
      .call(yAxis)
    .append("text")
      .attr("transform", "rotate(-90)")
      .attr("y", 6)
      .attr("dy", ".71em")
      .style("text-anchor", "end")
/*      .text("Number of Rounds");*/

  var selection = svg.selectAll(".series")
    .data(seriesArr)
    .enter().append("g")
      .attr("class", "series");

  selection.append("path")
    .attr("class", "streamPath")
    .attr("d", function (d) { return area(d.values); })
    .style("fill", function (d) { return color(d.name); })
    .style("stroke", "transparent");
  

  var points = svg.selectAll(".seriesPoints")
    .data(seriesArr)
    .enter().append("g")
      .attr("class", "seriesPoints");

  points.selectAll(".point")
    .data(function (d) { return d.values; })
    .enter().append("circle")
     .attr("class", "point")
     .attr("cx", function (d) { return x(d.label) + x.rangeBand() / 2; })
     .attr("cy", function (d) { return y(d.y0 + d.y); })
     .attr("r", "10px")
     .style("fill",function (d) { return color(d.name); })
     .on("mouseover", function (d) { showPopover.call(this, d); })
     .on("mouseout",  function (d) { removePopovers(); })

  var legend = svg.selectAll(".legend")
      .data(varNames.slice().reverse())
    .enter().append("g")
      .attr("class", "legend")
      .attr("transform", function (d, i) { return "translate(55," + i * 20 + ")"; });

  legend.append("rect")
      .attr("x", width - 10)
      .attr("width", 10)
      .attr("height", 10)
      .style("fill", color)
      .style("stroke", "grey");

  legend.append("text")
      .attr("x", width - 12)
      .attr("y", 6)
      .attr("dy", ".35em")
      .style("text-anchor", "end")
      .text(function (d) { return d; });

  function removePopovers () {
    $('.popover').each(function() {
      $(this).remove();
    }); 
  }

  function showPopover (d) {
    $(this).popover({
      title: d.name,
      placement: 'auto top',
      container: 'body',
      trigger: 'manual',
      html : true,
      content: function() { 
        return "Date: " + d.label + 
               "<br/>Rounds: " + d3.format(",")(d.value ? d.value: d.y1 - d.y0); }
    });
    $(this).popover('show')
  }

});

})();

// END Area Chart code

// BEGIN Area Chart code (daily totals only)

(function() {
var margin = {top: 20, right: 55, bottom: 30, left: 40},
    width  = 900 - margin.left - margin.right,
    height = 160  - margin.top  - margin.bottom;

var x = d3.scale.ordinal()
    .rangeRoundBands([0, width], .1);

var y = d3.scale.linear()
    .rangeRound([height, 0]);

var xAxis = d3.svg.axis()
    .scale(x)
    .orient("bottom");

var yAxis = d3.svg.axis()
    .scale(y)
    .orient("left");

var stack = d3.layout.stack()
    .offset("zero")
    .values(function (d) { return d.values; })
    .x(function (d) { return x(d.label) + x.rangeBand() / 2; })
    .y(function (d) { return d.value; });

var area = d3.svg.area()
    .interpolate("linear")
    .x(function (d) { return x(d.label) + x.rangeBand() / 2; })
    .y0(function (d) { return y(d.y0); })
    .y1(function (d) { return y(d.y0 + d.y); });

var color = d3.scale.ordinal()
    .range(["#f92672","#a6e22e","#66d9ef","#fd971f","#ae81ff"]);

var svg = d3.select("#area2").append("svg")
    .attr("width",  width  + margin.left + margin.right)
    .attr("height", height + margin.top  + margin.bottom)
  .append("g")
    .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

d3.json("/d3/area_chart2", function (error, data) {

  var labelVar = 'date';
  var varNames = d3.keys(data[0])
      .filter(function (key) { return key !== labelVar;});
  color.domain(varNames);

  var seriesArr = [], series = {};
  varNames.forEach(function (name) {
    series[name] = {name: name, values:[]};
    seriesArr.push(series[name]);
  });

  data.forEach(function (d) {
    varNames.map(function (name) {
      series[name].values.push({name: name, label: d[labelVar], value: +d[name]});
    });
  });

  x.domain(data.map(function (d) { return d.date; }));

  stack(seriesArr);

  y.domain([0, d3.max(seriesArr, function (c) { 
      return d3.max(c.values, function (d) { return d.y0 + d.y; });
    })]);

/*  svg.append("g")
      .attr("class", "x axis")
      .attr("transform", "translate(0," + height + ")")
      .call(xAxis);*/

  svg.append("g")
      .attr("class", "y axis")
      .call(yAxis)
    .append("text")
      .attr("transform", "rotate(-90)")
      .attr("y", 6)
      .attr("dy", ".71em")
      .style("text-anchor", "end")
/*      .text("Number of Rounds");*/

  var selection = svg.selectAll(".series")
    .data(seriesArr)
    .enter().append("g")
      .attr("class", "series");

  selection.append("path")
    .attr("class", "streamPath")
    .attr("d", function (d) { return area(d.values); })
    .style("fill", function (d) { return color(d.name); })
    .style("stroke", "transparent");
  

  var points = svg.selectAll(".seriesPoints")
    .data(seriesArr)
    .enter().append("g")
      .attr("class", "seriesPoints");

  points.selectAll(".point")
    .data(function (d) { return d.values; })
    .enter().append("circle")
     .attr("class", "point")
     .attr("cx", function (d) { return x(d.label) + x.rangeBand() / 2; })
     .attr("cy", function (d) { return y(d.y0 + d.y); })
     .attr("r", "10px")
     .style("fill",function (d) { return color(d.name); })
     .on("mouseover", function (d) { showPopover.call(this, d); })
     .on("mouseout",  function (d) { removePopovers(); })

  var legend = svg.selectAll(".legend")
      .data(varNames.slice().reverse())
    .enter().append("g")
      .attr("class", "legend")
      .attr("transform", function (d, i) { return "translate(55," + i * 20 + ")"; });

  legend.append("rect")
      .attr("x", width - 10)
      .attr("width", 10)
      .attr("height", 10)
      .style("fill", color)
      .style("stroke", "grey");

  legend.append("text")
      .attr("x", width - 12)
      .attr("y", 6)
      .attr("dy", ".35em")
      .style("text-anchor", "end")
      .text(function (d) { return d; });

  function removePopovers () {
    $('.popover').each(function() {
      $(this).remove();
    }); 
  }

  function showPopover (d) {
    $(this).popover({
      title: d.name,
      placement: 'auto top',
      container: 'body',
      trigger: 'manual',
      html : true,
      content: function() { 
        return "Date: " + d.label + 
               "<br/>Rounds: " + d3.format(",")(d.value ? d.value: d.y1 - d.y0); }
    });
    $(this).popover('show')
  }

});

})();

// END Area Chart code