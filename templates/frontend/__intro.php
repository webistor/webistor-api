<?php namespace components\webhistory; if(!defined('TX')) die('No direct access.'); ?>

<div class="hero-unit">
  <p>webhistory: an app that extends the human memory with a bit of web technology.</p>
</div>

<div class="span12">

  <h2>Webhistory</h2>
  <p>Webhistory is an webapp that allows you to save information you find on the web, so you can use the information later on.</p>

  <h2>How it works</h2>

  <h3>Add anything</h3>

  <div class="row">
    <div class="span4">
      <img src="http://2278766732.nl/upimg/2013q3/s-20131027-202956.png" />
    </div>
    <div class="span8">
      <ol>
        <li>Find something on the web</li>
        <li>Click on the 'Add to my webhistory' button</li>
        <li>Add tags, so you can find this entry really easily afterwards</li>
      </ol>
    </div>
  </div>

  <h3>Find anything</h3>

  <div class="row">
    <div class="span4">
      <img src="http://2278766732.nl/upimg/2013q3/s-20131027-203117.png" />
    </div>
    <div class="span8">
      <ol>
        <li>Fill in search term</li>
        <li>Browse search results</li>
      </ol>
    </div>
  </div>

  <h3>Explore subjects</h3>

  <p>
    The entry summary gets more interesting everyday. Explore your tag cloud to do research on any subject.
  </p>

  <h2>Cool, I want to have an account</h2>

  <p>
    You can create an account by filling in the form below. In the future we'll implement <a href="https://login.persona.org/" target="_blank">Persona</a> too, so you can login with your Persona account.
  </p>

  <?php
  echo tx('Component')->modules('account')->get_html('register');
  ?>

  <p>
    This webapp is in public beta. If you have feedback, please let us know :)
  </p>

  <h2>We love your feedback</h2>

  <div class="row">
    <div class="span4">
      <img src="http://2278766732.nl/upimg/2013q3/s-20131027-203200.png" />
    </div>
    <div class="span8">
      <p>When logged in, click on the 'Send feedback' button to talk with us and talk about possible improvements.</p>
    </div>
  </div>

</div>
