---
---
//

var cookies = document.cookie.split('; ');
var account = null;

cookies.forEach(function(c) {
  var name, value;
  [name,value] = c.split('=');
  if (name == 'email') {
    account = value;
  }
});

if (account) {
  var spans = document.querySelectorAll('span');

  spans.forEach(function(s) {
    if (s.innerText == '"your-conjur-account-id"') {
      s.innerText = '"' + account + '"';
    }
  });
}

$(document).ready(function() {

  $("form.hosted-account-signup").on("submit", function(event){
    event.preventDefault();
    $(this).fadeOut("normal", function(){
      $(this).next(".hosted-confirmation").slideDown("normal");
    });
  });

});
