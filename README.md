# 

## Introduction

The latest generation of client-side JavaScript frameworks has lead to a revival of the so-called one-page application. The browser downloads the source code for the core of the application at load time and uses Ajax requests, WebSockets, or other methods of communication to push and pull data from the server.

Unfortunately, there is a worrying trend when this application structure is applied to financial transactions and other sensitive data. All too often, developers assume that sending the sensitive data over HTTPS is enough security to protect the data. Although this does approach does protect the data from a passive eavesdropper, any party to the communication can execute a man-in-the-middle attack to capture the data without arousing a casual user's suspicion.

This document describes the vulnerability when the attacker controls the DNS settings of the network. This is not purely theoretical. Such an attack could easily be executed in practice by an unscrupulous public access point operator. There are a number of other ways of executing a similar attack given control of the router, but this one has the advantage of being very easy to execute and being possible from the stock firmware of most routers.

## Profile of Vulnerabile Applications

Any web application which takes sensitive data from an input form loaded over a non-encrypted channel is vulnerable to this class of attack. The particular proof-of-concept code described here is applicable to sites in which the sensitive data is entered by keyboard, but this is a limitation of the code provided and not the vulnerability. The extent of the vulnerability is that all "secure" data can be gathered without the user noticing any difference in the behaviour of the application.

The class of attack can occur whenever the attacker has control of the DNS or routing of unencrypted code (including HTML) about the application. This includes, for example, an application that is loaded over HTTP even if the application sends sensitive information over HTTPS.

## Description of the Attack

The attacker changes the DNS setting of the router to an IP under his control. The attacker runs a DNS server at that host which proxies DNS requests to an upstream host, except for a whitelist of sites which the attacker has identified as vulnerable to this attack. For those sites the DNS server returns an A-record mapping the domain to another IP under his control. At this IP he runs an HTTP-aware proxy server, which inserts JavaScript code into each page request. This JavaScript code contains a keylogger which captures each keystroke and reports it back to the proxy server at a special path which is intercepted and logged by the server.

## Preventing the Attack

In the same way that a chain is only as strong as its weakest link, a web application is only as secure as the least secure code element. The only solution is to serve the entire page which takes secure information over an HTTPS connection. This doesn't necessarily entail serving the whole application over HTTPS; the pages which deal with sensitive information could be extracted into an interaction that is served through HTTPS.

Years of end-user security training have taught users to look for the HTTPS lock icon in the browser chrome and not to trust sites that don't have it. The trend of legitimate sites displaying locks in the page content and asking the user to trust them is a dangerous step backwards for web security.

