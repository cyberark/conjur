---
---
//

function getAccountCookie() {
  var cookies = document.cookie.split('; ');

  for(var i = 0; i < cookies.length; i++) {
    var name, value;
    [name, value] = cookies[i].split('=');

    if(name == "account") {
      return JSON.parse(value);
    }
  }
  return null;
}

function setAccountCookie(value) {
  var date = new Date();
  date.setTime(date.getTime()+(120*24*60*60*1000));
  var expires = "; expires="+date.toGMTString();

  document.cookie = 'account=' + value + '; expires=' + expires + '; path=/';
}

function displayAccountCredentials(email, account, api_key) {
  $("#credentials-email").text(email);
  $("#credentials-account").text(account);
  $("#credentials-api-key").text(api_key);

  $('.hosted-conjur-signup').fadeOut("normal", function() {
    $('.hosted-conjur-signup').next(".hosted-confirmation").slideDown("normal");
  });

  var spans = document.querySelectorAll('span');

  spans.forEach(function(s) {
    if(s.innerText == '"your-conjur-account-id"') {
      s.innerText = '"' + account + '"';
    }
  });
}

$(document).ready(function() {
  var accountCookie = getAccountCookie();

  if(accountCookie !== null) {
    displayAccountCredentials(accountCookie.account,
                              accountCookie.account,
                              accountCookie.api_key);
  }

  $('.hosted-account-signup').validator().on('submit', function(e) {
    if(!e.isDefaultPrevented()) {
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
          setAccountCookie(JSON.stringify(response));
          displayAccountCredentials(response.account,
                                    response.account,
                                    response.api_key);
        },
        error: function(xhr, ajaxOptions, thrownError) {
          // Manually inserting the error here because there doesn't seem to
          // be a way to make bootstrap-validator display an error on-demand.
          var errorElement =
              '<ul class="list-unstyled"> \
                 <li style="color:#a94442">' +
                   xhr.responseJSON.message +
                '</li> \
              </ul>'

          $(".help-block.with-errors").first().html(errorElement);
        }
      });
    }
  });
});
