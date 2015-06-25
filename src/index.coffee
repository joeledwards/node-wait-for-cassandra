Q = require 'q'
cassandra = require 'cassandra-driver'
program = require 'commander'
durations = require 'durations'

# Wait for Cassandra to become available
waitForCassandra = (config) ->
  deferred = Q.defer()

  # timeouts in milliseconds
  connectTimeout = config.connectTimeout
  totalTimeout = config.totalTimeout

  quiet = config.quiet

  watch = durations.stopwatch().start()
  connectWatch = durations.stopwatch()

  attempts = 0

  clientOptions =
    contactPoints: [config.host]
    keyspace: config.keyspace
    protocolOptions:
      port: config.port
    socketOptions:
      connectTimeout: connectTimeout

  # Recursive connection test function
  client = new cassandra.Client(clientOptions)

  testConnection = () ->
    attempts += 1
    connectWatch.reset().start()
    client.execute 'describe keyspaces', (error, result) ->
      connectWatch.stop()
      if error?
        console.log "[#{error}] Attempt #{attempts} timed out. Time elapsed: #{watch}" if not quiet
        if watch.duration().millis() > totalTimeout
          console.log "Could not connect to Cassandra." if not quiet
          deferred.resolve 1
        else
          totalRemaining = Math.min connectTimeout, Math.max(0, totalTimeout - watch.duration().millis())
          connectDelay = Math.min totalRemaining, Math.max(0, connectTimeout - connectWatch.duration().millis())
          setTimeout testConnection, connectDelay
      else
        watch.stop()
        console.log "Connected. #{attempts} attempts over #{watch}"
        done()
        client.shutdown()
        deferred.resolve 0

  testConnection()

  deferred.promise

# Script was run directly
runScript = () ->
  program
    .option '-k, --keyspace <keyspace_name>', 'Cassandra keyspace to use (default is "system")'
    .option '-h, --host <hostname>', 'Cassandra host (default is localhost)'
    .option '-p, --port <port>', 'Cassandra port (default is 9042)', parseInt
    .option '-q, --quiet', 'Silence non-error output (default is false)'
    .option '-t, --connect-timeout <milliseconds>', 'Individual connection attempt timeout (default is 1000)', parseInt
    .option '-T, --total-timeout <milliseconds>', 'Total timeout across all connect attempts (default is 30000)', parseInt
    .parse(process.argv)

  config =
    host: program.host ? 'localhost'
    port: program.port ? 9042
    keyspace: program.keyspace ? 'system'
    connectTimeout: program.connectTimeout ? 1000
    totalTimeout: program.totalTimeout ? 30000
    quiet: program.quiet ? false

  waitForCassandra(config)
  .then (code) ->
    process.exit code

# Module
module.exports =
  await: waitForCassandra
  run: runScript

# If run directly
if require.main == module
  runScript()

