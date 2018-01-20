/**
 * AWS Lambda function to send a CloudWatch log group stream to Papertrail.
 *
 * @author Apiary Inc.
 * @author Tim Malone <tim@timmalone.id.au>
 */

const zlib = require( 'zlib' ),
      winston = require( 'winston' ),
      papertrailTransport = require( 'winston-papertrail' ).Papertrail;

const config = require( './env.json' );

exports.handler = ( event, context, callback ) => {
  context.callbackWaitsForEmptyEventLoop = config.waitForFlush;

  const payload = new Buffer( event.awslogs.data, 'base64' );

  zlib.gunzip( payload, ( error, result ) => {
    if ( error ) return callback( error );

    const log = new ( winston.Logger )({
      transports: []
    });

    log.add( papertrailTransport, {

      host:         config.papertrailHost,
      port:         config.papertrailPort,
      hostname:     config.lambdaName,
      program:      config.logGroup,
      flushOnClose: true,

      logFormat: ( level, message ) => {
        return message;
      }

    });

    const data = JSON.parse( result.toString( 'utf8' ) );

    data.logEvents.forEach( ( line ) => {
      log.info( line.message );
    });

    log.close();
    return callback();

  });
};
