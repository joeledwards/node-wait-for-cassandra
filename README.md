
Wait for Cassandra
===========

Waits for a Cassandra connection to become available, optionally running
a custom query to determine if the connection is valid.

Installation
============

```bash
npm install --save wait-for-cassandra
```

Usage
=====

Run as a module within another script:

```coffeescript
waitForCass = require 'wait-for-cassandra'
config =
  username: user
  password: pass
  quiet: true

waitForCass.wait(config)
```
      

Or run stand-alone

```bash
wait-for-cassandra --username=user --password=pass --quiet
```

Building
============

cake build

