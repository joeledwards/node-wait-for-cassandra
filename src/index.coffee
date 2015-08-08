Q = require 'q'
cassandra = require 'cassandra-driver'
program = require 'commander'
durations = require 'durations'

# Wait for Cassandra to become available
waitForCassandra = (config, totalTimeout=30000, quiet=false) ->
  deferred = Q.defer()

  watch = durations.stopwatch().start()
  connectWatch = durations.stopwatch()
  connectTimeout = config?.socketOptions?.connectTimeout ? 1000

  attempts = 0

  testConnection = () ->
    attempts += 1
    connectWatch.reset().start()
    client = new cassandra.Client(config)
    client.connect (error) ->
      if error?
        console.log "[#{error}] Attempt #{attempts} timed out. Time elapsed: #{watch}" if not quiet
        if watch.duration().millis() > totalTimeout
          console.log "Could not connect to Cassandra." if not quiet
          client.shutdown()
          deferred.resolve false
        else
          client.shutdown()
          totalRemaining = Math.min connectTimeout, Math.max(0, totalTimeout - watch.duration().millis())
          connectDelay = Math.min totalRemaining, Math.max(0, connectTimeout - connectWatch.duration().millis())
          setTimeout testConnection, connectDelay
      else
        watch.stop()
        console.log "Connected. #{attempts} attempts over #{watch}" if not quiet
        client.shutdown()
        deferred.resolve true

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

  connectTimeout = program.connectTimeout ? 1000
  totalTimeout = program.totalTimeout ? 30000
  quiet = program.quiet ? false

  config =
    contactPoints: [program.host ? 'localhost']
    keyspace: program.keyspace ? 'system'
    protocolOptions:
      port: program.port ? 9042
    socketOptions:
      connectTimeout: connectTimeout

  waitForCassandra(config, totalTimeout,  quiet)
  .then (connected) ->
    code = if connected then 0 else 1
    process.exit code

# Module
module.exports =
  await: waitForCassandra
  run: runScript

# If run directly
if require.main == module
  runScript()

