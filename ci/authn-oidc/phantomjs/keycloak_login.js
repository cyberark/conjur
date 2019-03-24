var steps=[];
var testindex = 0;
var loadInProgress = false;//This is set to true when a page is still loading

/*********SETTINGS*********************/
var webPage = require('webpage');

var page = webPage.create();
var system = require('system');
var env = system.env;
var fs = require('fs');
var date = Date.now().toString();
var logfile = 'keycloak_login.' + date + '.log';
log('Date in container: ' + date);
page.settings.userAgent = 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.157 Safari/537.36';
page.settings.javascriptEnabled = true;
page.settings.loadImages = false;//Script is much faster with this field set to false
phantom.cookiesEnabled = true;
phantom.javascriptEnabled = true;
/*********SETTINGS END*****************/

log('All settings loaded, start with execution');
page.onConsoleMessage = function(msg) {
    log(msg);
};
/**********DEFINE STEPS THAT PHANTOM SHOULD DO***********************/
steps = [


    function(){
        log('Open keycloak home page');
        var authorize_request = "https://keycloak:8443/auth/realms/master/protocol/openid-connect/auth";
        authorize_request = authorize_request + "?client_id=" + env['CLIENT_ID'];
        authorize_request = authorize_request + "&response_type=code&response_mode=query";
        authorize_request = authorize_request + "&scope=" + env['SCOPE'].replace(/,/g, " ");
        authorize_request = authorize_request + "&redirect_uri=" + env['REDIRECT_URI'];
        log('Rest request : ' + authorize_request.toString());
        //http://keycloak:8080/auth/admin
        //example to request: http://keycloak:8080/auth/realms/master/protocol/openid-connect/auth?client_id=myclient&response_type=code&response_mode=query&scope=openid profile&redirect_uri=http://locallhost.com/"
        page.open(authorize_request.toString(), function(status){
          log('Rest request status: ' + status);
		});
    },

    function(){
        log('Populate and submit the login form');
        page.evaluate(function(){
          document.getElementById("username").value = "TO_BE_REPLACED_USER";
          document.getElementById("password").value = "TO_BE_REPLACED_PASSSWORD";
          document.getElementById("kc-login").click();
         });
    },

    function(){
         log("Wait for keycloak to login user");
         var result = page.evaluate(function() {
           return document.querySelectorAll("html")[0].outerHTML;
         });
         var code = result.substring(result.indexOf('code=') + 5, result.length);
         code = code.substring(0, code.indexOf('>http') - 1);
         log('authorization code=' + code);
         fs.write('authorization_code',code,'w');
    },
];
/**********END STEPS THAT PHANTOM SHOULD DO***********************/

//Execute steps one by one
interval = setInterval(executeRequestsStepByStep,50);

function executeRequestsStepByStep(){
    if (loadInProgress == false && typeof steps[testindex] == "function") {
        steps[testindex]();
        testindex++;
    }
    if (typeof steps[testindex] != "function") {
        log("test complete!");
        phantom.exit();
    }
}

function log(msg) {
    console.log(msg);
    fs.write(logfile,msg,'a');
}

/**
 * These listeners are very important in order to phantom work properly. Using these listeners, we control loadInProgress marker which controls, weather a page is fully loaded.
 * Without this, we will get content of the page, even a page is not fully loaded.
 */
page.onLoadStarted = function() {
    loadInProgress = true;
    log('Loading started');
};
page.onLoadFinished = function() {
    loadInProgress = false;
    log('Loading finished');
};
page.onConsoleMessage = function(msg) {
    log(msg);
};
