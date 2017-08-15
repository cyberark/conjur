---
---
//

function displayAccountCredentials(email, account, api_key) {
  $("#credentials-email").text(email);
  $("#credentials-account").text(account);
  $("#credentials-api-key").text(api_key);

  $('.hosted-account-signup').fadeOut("normal", function(){
    $('.hosted-account-signup').next(".hosted-confirmation").slideDown("normal");
  });
}

$(document).ready(function() {
  document.cookie.split('; ').forEach(function(c) {
    var name, value;
    [name,value] = c.split('=');

    if(name == "account") {
      account_data = JSON.parse(value);
      displayAccountCredentials(account_data.account,
                                account_data.account,
                                account_data.api_key);
    }
  });

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
          document.cookie = "account="+JSON.stringify(response);
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
