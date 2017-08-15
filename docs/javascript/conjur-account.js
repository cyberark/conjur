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

  $('.hosted-account-signup').validator({
    custom: {
      'odd': function($el) {
        console.log($el.val());
        return "Hey, that is wrong!";
      }
    }
  }).on('submit', function (e) {
    if (e.isDefaultPrevented()) {
      // handle the invalid form...
    } else {
      e.preventDefault(); // TODO - remove when form is actually able to be submitted.
      $(this).fadeOut("normal", function(){
        $(this).next(".hosted-confirmation").slideDown("normal");
      });
    }
  })

});
