var editor = ace.edit("editor");
editor.setTheme("/javascripts/theme-monokai.js")

var the_data = "/eureka"
$(function() {
    $( ".draggable" ).draggable();
 });

$(function() {
    $( "#tabs" ).tabs();
});


$(function() {
  $( "#slider-range-max" ).slider({
    min: 0,
    max: 36,
    value: 2,
    step: 1,
    slide: function( event, ui ) {
      $( "#amount" ).val( ui.value );
    }
  });
  
  $( "#amount" ).val( $( "#slider-range-max" ).slider( "value" ) );
  
});

 $(function() {
  $( "#eq > span" ).each(function() {
    // read initial values from markup and remove that
    var value = parseInt( $( this ).text(), 10 );
    $( this ).empty().slider({
      value: value,
      animate: true,
      orientation: "vertical"
    });
  });
});



var calendar = new CalHeatMap();
      calendar.init({
          data: "http://localhost:4567/d3",
          start: new Date(2014, 1),
          id : "graph_f",
          domain : "month",
          subDomain : "hour",
          rowLimit : 24,
          scale: [1,1,2,2],
          range : 3,
          cellSize: 7,
          cellpadding: 1
      });

var d = new Date();
d.setMinutes(d.getMinutes() + 25);
$('#timer').tinyTimer({ to: d });


$(document).foundation();