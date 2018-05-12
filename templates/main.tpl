<html>
<head>
{{>HEADER_TEMPLATE}}
</head>

<body>

  {{>NAVBAR_TEMPLATE}}
  <div class="jumbotron text-center">
   <h1>{{PAGENAME}}</h1>
   <p>

     Uri: {{URI}}
     </p>
    <p>
     Route: {{ROUTE}}
   </p>
   <p>
     {{MESSAGE}}
   </p>
  </div>

  <!-- <div class="container">
   <div class="row">
     <div class="col-sm-4">
       <a class="btn-primary btn-lg" href="http://killapixel.net/certstore">Certificate Store</a>


     </div>
     <div class="col-sm-4">
       <a class="btn-primary btn-lg" href="http://killapixel.net/seafile">Seafile</a>
     </div>
     <div class="col-sm-4">
       <a class="btn-primary btn-lg" href="http://killapixel.net/radicale">Radicale</a>
     </div>
   </div>
  </div> -->

{{>JAVASCRIPT_TEMPLATE}}
</body>
</html>
