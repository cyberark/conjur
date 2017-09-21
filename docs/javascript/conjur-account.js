---
---
//

function getCookieValue(cookieName) {
  var cookies = document.cookie.split('; ');

  for(var i = 0; i < cookies.length; i++) {
    var name, value;
    [name, value] = cookies[i].split('=');

    if(name == cookieName) {
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

function displayAccountCredentials(email, account_id, api_key) {
  $("#credentials-email").text(email);
  $("#credentials-account").text(account_id);
  $("#credentials-api-key").text(api_key);

  $('.hosted-conjur-signup').fadeOut("normal", function() {
    $('.hosted-conjur-signup').next(".hosted-confirmation").slideDown("normal");
  });

  var spans = document.querySelectorAll('span');

  spans.forEach(function(s) {
    if(s.innerText == '"your-conjur-account-id"') {
      s.innerText = '"' + account_id + '"';
    }
  });

  updateClipboardButtons();
}

function displayError(formField, message) {
  // Manually inserting the error here because there doesn't seem to
  // be a way to make bootstrap-validator display an error on-demand.
  var errorElement =
    '<ul class="list-unstyled"> \
      <li class="form-error">' +
        message +
     '</li> \
     </ul>'

  formField.siblings(".help-block.with-errors").first().html(errorElement);
}

$(document).ready(function() {
  var accountCookie = getCookieValue("account");

  if(accountCookie !== null) {
    displayAccountCredentials(accountCookie.account_id,
                              accountCookie.account_id,
                              accountCookie.api_key);
  }

  $('.hosted-account-signup').validator().on('submit', function(e) {
    if(!e.isDefaultPrevented()) {
      e.preventDefault();

      var recaptchaToken = grecaptcha.getResponse();
      
      if(recaptchaToken === "") {
        displayError($("#recaptcha").first(), "Please complete reCAPTCHA.");
        return;
      }

      var hutk = getCookieValue("hubspotutk");
      
      var payload =
          "email=" + $("#email-address").val() +
          "&organization=" + $("#organization").val() +
          "&recaptcha_token=" + recaptchaToken +
          "&hutk=" + hutk;
      
      $.ajax({
        context: this,
        type: "POST",
        data: payload,
        url: "{{site.cpanel_url}}/api/accounts",
        success: function(response) {
          setAccountCookie(JSON.stringify(response));
          displayAccountCredentials(response.email,
                                    response.account_id,
                                    response.api_key);
        },
        error: function(xhr, ajaxOptions, thrownError) {
          if(xhr.responseJSON === undefined) { return; }
          
          var error = xhr.responseJSON.error;
          var formField;
          
          if(error.target == "email") {
            formField = $("#email-address").first();
          } else if(error.target == "organization") {
            formField = $("#organization").first();
          } else if(error.target == "recaptcha") {
            formField = $("#recaptcha").first();
          }

          if(formField !== undefined && error !== undefined) {
            displayError(formField, error.message);
          }
        }
      });
    }
  });
});
