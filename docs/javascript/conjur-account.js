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
  $('.hosted-account-signup').validator().on('submit', function(e) {
    if(e.isDefaultPrevented()) {
      // handle the invalid form...
    } else {
      e.preventDefault();

      $.ajax({
        context: this,
        type: "POST",
        data: "email=" + $("#email-address").val(),
        {% if site.env == 'production' %}
        url: "https://possum-cpanel-conjur.herokuapp.com/api/accounts"
        {% else %}
        url: "http://localhost:3000/api/accounts",
        {% endif %}
        success: function(response) {
          $("#credentials-email").text(response.account);
          $("#credentials-account").text(response.account);
          $("#credentials-api-key").text(response.api_key);
          
          $(this).fadeOut("normal", function(){
            $(this).next(".hosted-confirmation").slideDown("normal");
          });
        },
        error: function(xhr, ajaxOptions, thrownError) {
          // Manually inserting the error here because there doesn't seem to
          // be a way to make bootstrap-validator display an error on-demand.
          var error = '<ul class="list-unstyled"><li>'+xhr.responseJSON.message+'</li></ul>'
          $(".help-block.with-errors").first().html(error);
        }
      });
    }
  });
});
