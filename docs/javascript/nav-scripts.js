---
---
//

$(document).ready(function() {

  $("#mobile-navigation li.has-menu > a").on("click", function(event){
    event.preventDefault();
    $(this).siblings("ul.nav-menu").slideToggle("fast");
  });

  $("#top-navigation a[href='#']").on("click", function(event){
    event.stopPropagation();
    event.preventDefault();
  });

});
