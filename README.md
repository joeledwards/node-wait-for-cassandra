
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
  contactPoints: ['localhost']
  keyspace: 'test'
  protocolOptions:
    port: 9043
  socketOptions:
    connectTimeout: 3000

waitForCass.wait(config, 20000, true)
.then (result) ->
  message = if result then "Online" else "Offline"
  console.log "Cassandra is #{message}"
```
      

Or run stand-alone

```bash
wait-for-cassandra --username=user --password=pass --quiet
```

Building
============

cake build

