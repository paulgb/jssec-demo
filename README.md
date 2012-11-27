
JSSec-Demo
==========

Introduction
------------

This code runs on a server controlled by the "attacker". The only server requirement
is Node.js; all other requirements are installed automatically during the package
installation process.

Warning
-------

The purpose of this code is to demonstrate a class of vulnerability. Use it at your
own risk and don't use it to break any laws.

Installation
------------

First, install node.js, available at [nodejs.org](http://nodejs.org/).

Once node.js is installed, change into the directory containing `package.json`
and run

    npm install

This will install some packages locally that the exploit depends on.

Setup
-----

The exploit server expects three environment variables to be set.

`PUBLIC_IP` should be set to the public IP of the server which runs the exploit.

`TAP_HOST` should be set to the domain or subdomain on which you wish to inject
the exploit code.

`UPSTREAM_DNS` should be set to the IP of a domain server.

TCP ports 53 (DNS), 80 (HTTP), and 443 (HTTPS) should be open (ie. not behind a
firewall) on the server. Additionally, the user wishing to run the server should
be able to open these ports. For convinience, a start script using authbind
is provided, but setting up authbind will not be covered here.

Running
-------

To run the server, simply run `npm start` in the directory containing `package.json`.

If you get permission errors, you may need to set up authbind and run
`npm runscript startauth` or run the script as `root` by running `sudo npm start`.

If things are working, you should see messages print to the console indicating that
the HTTP and TCP servers are listening.

Performing the Exploit
----------------------

Change the DNS settings on a router to point to the IP of the server (which should
be whatever you set `PUBLIC_IP` to).

Open the site which you set `TAP_HOST` to in the browser. You should see a message
that the DNS request has been intercepted. You should also see a message that one
or more pages has been injected, meaning that the keylogger has been inserted into
the code.

Once this has happened, you can navigate around the site. Any keystrokes you make
will be sent to the server and logged to the console, even if they are entered
into a "secure" form.

Avoiding the Exploit
--------------------

The only real way to avoid this class of exploit is to *only ask for sensitive
information on pages that have been loaded over HTTPS*. Any other solution is
a hack and while it may outsmart this general proof-of-concept exploit, it *will*
be vulnerable to attacks of the same class.

