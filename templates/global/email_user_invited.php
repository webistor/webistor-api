<?php namespace components\account; if(!defined('TX')) die('No direct access.'); ?>
<html>
  <head>

    <title></title>

    <style type="text/css">

    @font-face {
      font-family: 'ProximaNova Regular';
      src: url("http://www.webistor.net/fonts/proximanova-regular-webfont.eot");
      src: url("http://www.webistor.net/fonts/proximanova-regular-webfont.eot?#iefix") format('embedded-opentype'), url("http://www.webistor.net/fonts/proximanova-regular-webfont.woff") format('woff'), url("http://www.webistor.net/fonts/proximanova-regular-webfont.ttf") format('truetype'), url("http://www.webistor.net/fonts/proximanova-regular-webfont.svg#proxima_nova_rgregular") format('svg');
      font-weight: normal;
      font-style: normal;
    }

    html, body{width:100%;font-size:16px;line-height:24px;font-family:'ProximaNova Regular', sans-serif;}

    a{color:#67737a;text-decoration:none;}
    a:hover{opacity:0.9;-webkit-filter: contrast(102%);}

    </style>

  </head>
  <body>

<div style="background-color:#f8f9fa;width:100%;">

  <div style="margin:32px auto;width:375px;max-width:98%;background:#fff;border:solid #dfe4e6 1px;color:#67737a;padding:32px 85px 32px 85px;">

    <div style="background-color:#f8f9fa;display:block;padding:0;width:188px;height:181px;margin:0 auto;">
      <img src="http://www.webistor.net/images/mail/approved-illustration.png" alt="You're invited!" title="You're invited!">
    </div>

    <h1 style="font-size:20px;font-weight:bold;">Well done! You can use Webistor now.</h1>

    <p>
      Hi, thank you for signing up for the private b&egrave;ta of <a href="http://www.webistor.net" target="_blank" style="color:#67737a;font-weight:bold;">Webistor</a>! You're invited to join us. Click on the button below to continue.
    </p>

    <p style="text-align:center;">
      <a href="<?php echo $data->claim_link; ?>" style="border-radius:2px;display:inline-block;background:#a0d468;padding:10px 22px;color:#fff;text-align:center;margin:0 auto;font-weight:bold;font-size:16px;" target="_blank">Create your account</a>
    </p>

    <p>
      We're really excited to continue to add more power to Webistor over the coming months for you, so I'd love to hear any thoughts you have on the direction and features.
    </p>

    <p>
      As with every one of our emails, just hit reply and we'll respond back right away! :)
    </p>

    <p>
      <b>- Bart and the Webistor team</b>
    </p>

  </div>

</div>

  </body>
</html>