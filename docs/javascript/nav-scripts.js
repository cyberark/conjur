---
---
//

$(document).ready(function() {

  $("#mobile-navigation li.has-menu > a").on("click", function(event){
    event.preventDefault();
    $(this).siblings("ul.nav-menu").slideToggle("fast");
  });

});
