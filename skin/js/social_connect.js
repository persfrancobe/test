 ///////////////////
// CONFIGURATION //
///////////////////

var apps_config = {
  "google-clientID"             :  "822615544018-o0oop8cop1qk8cdtg8m9u0rq1vffpor3.apps.googleusercontent.com",
  "facebook-appID"              :  "763999000363303",
};



$(document).ready(function(){
  
  $(".connect-facebook").click(function(){
    FB.login(function(response) {
      statusChangeCallback(response);
    },
    {
      scope: "public_profile,email,user_birthday,user_location"
    });

    return false;
  })

  $(".connect-google").click(function(){

    gapi.auth.signIn(
      {
        'clientid' : apps_config["google-clientID"],
        'cookiepolicy' : 'single_host_origin',
        'callback' : 'signinCallback',
        'requestvisibleactions': 'http://schemas.google.com/AddActivity',
        'scope': 'https://www.googleapis.com/auth/plus.login https://www.googleapis.com/auth/userinfo.email',
      }
    ) 



    return false;
    });

});



function connexion(infos) {
  
  var social_id        = infos["id"];
  var social_token     = infos["token"];
  var social_email     = infos["email"];
  var social_lastname  = infos["lastname"];
  var social_firstname = infos["firstname"];
  var social_city      = infos["city"];
  var social_country   = infos["country"];
  var social_birthdate = infos["birthdate"];
  var social_type      = infos["type"];

  var request = $.ajax(
  {
      url: 'cgi-bin/eshop.pl',
      type: "POST",
      data: 
      {
        sw : 'login_db',
        social_id : social_id,
        social_token : social_token,
        social_email: social_email,
        social_lastname: social_lastname,
        social_firstname: social_firstname,
        social_city: social_city,
        social_country: social_country,
        social_birthdate: social_birthdate,
        social_type: social_type,       
      },
      dataType: "html"
  });

  request.done(function(msg) 
  {
    // On récupère l'url de redirection
    var link = $(".newaccount-form a").attr("href");
    console.log(link);
    window.location = link;
  });
  request.fail(function(jqXHR, textStatus) 
  {
      
  });

}

//////////////
// FACEBOOK //
//////////////

// This is called with the results from FB.getLoginStatus().
function statusChangeCallback(response) {
// The response object is returned with a status field that lets the
// app know the current login status of the person.
// Full docs on the response object can be found in the documentation
// for FB.getLoginStatus().
if (response.status === 'connected') {
  // Logged into your app and Facebook.
  // Get the user's infos
  var token = response.authResponse.accessToken;
  FB.api("/me", function(response){
    
    if(response && !response.error) {
      var id = response.id;
      var lastname  = typeof response.last_name != "undefined" ? response.last_name : "";
      var firstname = typeof response.first_name != "undefined" ? response.first_name : "";
      if(typeof response.location != "undefined") {
        var city      = typeof response.location.name != "undefined" ? response.location.name.substr("0",response.location.name.indexOf(",")) : "";
        var country   = typeof response.location.name != "undefined" ? response.location.name.substr(response.location.name.indexOf(",")+1).trim() :"";
      }
      else {
        var city = "";
        var country = "";
      }
     
      var birthdate = typeof response.birthday != "undefined" ? response.birthday.substr(response.birthday.lastIndexOf("/")+1) : "";
      var email     = typeof response.email != "undefined" ? response.email : "";

      var infos = {
          "lastname"      :  lastname,
          "firstname"     :  firstname,
          "city"          :  city,
          "country"       :  country,
          "birthdate"     :  birthdate,
          "email"         :  email,
          "token"         : token,
          "id"            : id,
          "type"          : "facebook_signup",
      }             
    }
    connexion(infos);         
  })
  } else if (response.status === 'not_authorized') {
    // The person is logged into Facebook, but not your app.
  } else {
    // The person is not logged into Facebook, so we're not sure if
    // they are logged into this app or not.
  }
}

// This function is called when someone finishes with the Login
// Button.  See the onlogin handler attached to it in the sample
// code below.
function checkLoginState() {
FB.getLoginStatus(function(response) {
  statusChangeCallback(response);
});
}

window.fbAsyncInit = function() {
FB.init({
  appId      : apps_config["facebook-appID"],
  cookie     : true,  // enable cookies to allow the server to access 
                      // the session
  xfbml      : true,  // parse social plugins on this page
  version    : 'v2.1' // use version 2.1
});

// Now that we've initialized the JavaScript SDK, we call 
// FB.getLoginStatus().  This function gets the state of the
// person visiting this page and can return one of three states to
// the callback you provide.  They can be:
//
// 1. Logged into your app ('connected')
// 2. Logged into Facebook, but not your app ('not_authorized')
// 3. Not logged into Facebook and can't tell if they are logged into
//    your app or not.
//
// These three cases are handled in the callback function.

// FB.getLoginStatus(function(response) {
// statusChangeCallback(response);
// });

};

// Load the SDK asynchronously
(function(d, s, id){
     var js, fjs = d.getElementsByTagName(s)[0];
     if (d.getElementById(id)) {return;}
     js = d.createElement(s); js.id = id;
     js.src = "//connect.facebook.net/en_US/sdk.js";
     fjs.parentNode.insertBefore(js, fjs);
   }(document, 'script', 'facebook-jssdk'));






/////////////
// GOOGLE+ //
/////////////
(function() {
var po = document.createElement('script'); po.type = 'text/javascript'; po.async = true;
po.src = 'https://apis.google.com/js/client:plusone.js';
var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(po, s);
})();

$("#googleContainer").css({
"display" : "inline-block",
"position": "absolute",
"left"    : "115px",
"top"     : "6px",
});


function signinCallback(authResult) {
if (authResult['access_token']) {

gapi.client.load('oauth2', 'v2', function()
{
  gapi.client.oauth2.userinfo.get()
    .execute(function(resp)
    {
      // Shows user email
      // console.log(resp);
      var lastname  = typeof resp.family_name != "undefined" ? resp.family_name : "";
      var firstname = typeof resp.given_name != "undefined" ? resp.given_name : "";
      var email     = typeof resp.email != "undefined" ? resp.email : "";
      var token     = authResult.access_token;
      var id        = typeof resp.id != "undefined" ? resp.id : "";

      var infos = {
        "lastname"      :  lastname,
        "firstname"     :  firstname,
        "email"         :  email,
        "token"         : token,
        "id"            : id,
        "type"          : "google_signup",
      }

      connexion(infos);         
    });
});

} else if (authResult['error']) {
// Une erreur s'est produite.
// Codes d'erreur possibles :
//   "access_denied" - L'utilisateur a refusé l'accès à votre application
//   "immediate_failed" - La connexion automatique de l'utilisateur a échoué
// console.log('Une erreur s'est produite : ' + authResult['error']);
}
}

/////////////
// TWITTER //
/////////////
