<?php

// trace($data->dump());

?>

<h2>New users chart, last 8 months</h2>
<div id="new_users_chart"></div>

<?php echo $data->map(function($row){ return $row; })->join(', '); ?>

<script>

//Define data to show in chart.
var y = [<?php echo $data->map(function($row){ return $row; })->join(', '); ?>];

var x = [];
for (var i = 0; i < y.length; i++) {
  x[i] = i;
}

//Create line chart.
var r = Raphael("new_users_chart")

r.linechart

  (0, 0, 800, 400, x, y, {
  
    smooth: true,
    colors: ['#000'],
    symbol: 'circle', 'width': 2

  })

  .hoverColumn(function () {
    this.tags = r.set();

    for (var i = 0, ii = this.y.length; i < ii; i++) {
        this.tags.push(r.tag(this.x, this.y[i], this.values[i], 160, 10).insertBefore(this).attr([{ fill: "#fff" }, { fill: this.symbols[i].attr("fill") }]));
    }
  }, function () {
    this.tags && this.tags.remove();
  });

</script>

<style>
h2{
  text-align:center;
}
#new_users_chart{
  margin:50px auto;
  width:800px;
  height:400px;
}
</style>