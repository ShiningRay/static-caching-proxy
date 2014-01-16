rewire = require("rewire")
FS = require 'fs-mock'
Should = require 'should'
content = """
<!doctype html>
<html lang="en">
  <head>
  <meta charset="utf-8">
    <link type="image/x-icon" rel="icon" href="favicon.ico">
    <link type="image/x-icon" rel="shortcut icon" href="favicon.ico">
    <link rel="stylesheet" href="pipe.css">
    <link rel="stylesheet" href="sh_vim-dark.css">
    <link rel="alternate"
          type="application/rss+xml"
          title="node blog"
          href="http://feeds.feedburner.com/nodejs/123123123">
    <title>node.js</title>
  </head>
  <body id="front">
    <div id="intro">
        <img id="logo" src="http://nodejs.org/images/logo.png" alt="node.js">

        <p>Node.js is a platform built on <a
        href="http://code.google.com/p/v8/">Chrome's JavaScript runtime</a>
        for easily building fast, scalable network applications.  Node.js
        uses an event-driven, non-blocking I/O model that makes it
        lightweight and efficient, perfect for data-intensive real-time
        applications that run across distributed devices.</p>

        <p>Current Version: v0.10.24</p>

        <div class=buttons>
        <a href="http://nodejs.org/dist/v0.10.24/node-v0.10.24.tar.gz" class="button downloadbutton" id="downloadbutton">INSTALL</a>

        <a href="download/" class=button id="all-dl-options">Downloads</a
        ><a href="api/" class="button" id="docsbutton">API Docs</a>
        </div>

        <a href="http://github.com/joyent/node"><img class="forkme" src="http://nodejs.org/images/forkme.png" alt="Fork me on GitHub"></a>
    </div>

    <div id="quotes" class="clearfix"><h2>Node.js in the Industry</h2><ul><li class="madglory"><img src="industry/data/madglory/logo.png" alt="logo" height=34><p>We specialize in building custom service platforms and web applications that scale to tens of millions of users.
The ability to use a single language on both front-end and back-end, the great tooling support, the
thriving module ecosystem, and the evented programming model make Node our go-to tool for anything that requires massive scale. The best part? The community is wonderfully supportive and shares a common interest in moving the web forward.
<br>
<a href="http://www.madgloryint.com">Brian Corrigan</a>
<br>
<span>CEO</span></p>
</li>
<li class="fandist"><img src="industry/data/fandist/logo.png" alt="logo" height=34><p>
  Node.js allowed us to create a highly scalable cloud based application
  with ease. In addition its event-driven nature perfectly suited the
  model of our realtime advocacy platform.
  <br/>
  <a href="http://fandi.st/">Paul Inman</a>
  <br/>
  <span>CTO</span>
</p>
</li>
<li class="kwiqly"><img src="industry/data/kwiqly/logo.png" alt="logo" height=34><p>Node.js bridges the gap beween rock solid technologies (e.g. LaTex, R, ...) and state of the art web application development.  All our software products are based on Node.
<br>
<a href="http://kwiqly.com">Andreas Mueller</a>
<br>
<span>CTO</span></p>
</li>
<li class="nodejitsu"><img src="industry/data/nodejitsu/logo.png" alt="logo" height=34><p>
  Node.js allows us to easily orchestrate thousands of servers in our cloud
  and yours. The simple non-blocking network programming model allows us to
  work with sockets and network traffic with a lower server footprint than
  anything else available today.
  <br/>
  <a href="http://nodejitsu.com">Charlie Robbins</a>
  <br/>
  <span>CEO</span>
</p>
</li></ul><h2 style="clear:both"><a href="/industry/">More...</a></h2></div>

    <div id="content" class="clearfix">
            <div id="column1">
                <h2>An example: Webserver</h2>
                <p>This simple web server written in Node responds with "Hello World" for every request.</p>
              <pre>
var http = require('http');
http.createServer(function (req, res) {
  res.writeHead(200, {'Content-Type': 'text/plain'});
  res.end('Hello World\n');
}).listen(1337, '127.0.0.1');
console.log('Server running at http://127.0.0.1:1337/');</pre>

              <p>To run the server, put the code into a file
              <code>example.js</code> and execute it with the
              <code>node</code> program from the command line:</p>
              <pre class="sh_none">
% node example.js
Server running at http://127.0.0.1:1337/</pre>

                <p>Here is an example of a simple TCP server which listens on port 1337 and echoes whatever you send it:</p>

                <pre>
var net = require('net');

var server = net.createServer(function (socket) {
  socket.write('Echo server\r\n');
  socket.pipe(socket);
});

server.listen(1337, '127.0.0.1');</pre>

                <!-- <p>Ready to dig in? <a href="">Download the latest version</a> of node.js or learn how other organizations are <a href="">using the technology</a>.</p> -->
        </div>
        <div id="column2">
            <h2>Featured</h2>
            <a href="http://www.youtube.com/watch?v=jo_B4LTHi3I"><img src="http://nodejs.org/images/ryan-speaker.jpg"></a>
            A guided introduction to Node

            <h2>Explore Node.js</h2>
            <ul id="explore">
                <li><a href="about/" class="explore">About</a><br><span>Technical overview</span></li>
                <li><a href="http://npmjs.org/" class="explore">npm Registry</a><br><span>Modules, resources and more</span></li>
                <li><a href="http://nodejs.org/api/" class="explore">Documentation</a><br><span>API Specifications</span></li>
                <li><a href="http://blog.nodejs.org" class="explore">Node.js Blog</a><br><span>Insight, perspective and events</span></li>
                <li><a href="community/" class="explore">Community</a><br><span>Mailing lists, blogs, and more</span></li>
                <li><a href="logos/" class="explore">Logos</a><br><span>Logo and desktop background</span></li>
                <li><a href="http://jobs.nodejs.org/" class="explore">Jobs</a><br><ol class="jobs"><!-- JOBS --><li><a href='http://jobs.nodejs.org/a/jbb/redirect/972037'>creativeLIVE</a></li><li><a href='http://jobs.nodejs.org/a/jbb/redirect/971878'>Faithology, LLC</a></li><li><a href='http://jobs.nodejs.org/a/jbb/redirect/971569'>Signpost</a></li><li><a href='http://jobs.nodejs.org/a/jbb/redirect/971564'>Signpost</a></li><li><a href='http://jobs.nodejs.org/a/jbb/redirect/971563'>Signpost</a></li><li><a href='http://jobs.nodejs.org/a/jbb/redirect/969020'>Grokker</a></li><!-- JOBS --></ol></li>
            </ul>
    </div>
</div>

    <div id="footer">
        <a href="http://joyent.com" class="joyent-logo">Joyent</a>
        <ul class="clearfix">
            <li><a href="/">Node.js</a></li>
            <li><a href="/download/">Download</a></li>
            <li><a href="/about/">About</a></li>
            <li><a href="http://npmjs.org/">npm Registry</a></li>
            <li><a href="http://nodejs.org/api/">Docs</a></li>
            <li><a href="http://blog.nodejs.org">Blog</a></li>
            <li><a href="/community/">Community</a></li>
            <li><a href="/logos/">Logos</a></li>
            <li><a href="http://jobs.nodejs.org/">Jobs</a></li>
        </ul>

        <p>Copyright <a href="http://joyent.com/">Joyent, Inc</a>, Node.js is a <a href="/trademark-policy.pdf">trademark</a> of Joyent, Inc. View <a href="https://raw.github.com/joyent/node/v0.10.24/LICENSE">license</a>.</p>
    </div>
    <script src="sh_main.js"></script>
    <script src="sh_javascript.min.js"></script>
 </body>
</html>


"""
prefetcher = rewire '../server/prefetcher'
describe 'prefetcher', ->
  beforeEach ->
    fs = new FS
      "/tmp/cache/index.html": content
    prefetcher.__set__('fs', fs)
  it 'should extract href on a tag', (done) ->
    prefetcher.prefetch "http://nodejs.org/", "/tmp/cache/index.html", (err, queue) ->
      return done(err) if err
      try
        for i in [
            'http://nodejs.org/sh_main.js',
            "http://nodejs.org/sh_javascript.min.js",
            "http://jobs.nodejs.org/",
            "http://nodejs.org/logos/"]
          queue.should.contain(i)
        done()
      catch e
        done(e)

