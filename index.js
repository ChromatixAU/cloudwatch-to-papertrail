/**
 * AWS Lambda function to send a CloudWatch log group stream to Papertrail.
 *
 * @author Apiary Inc.
 * @author Tim Malone <tim@timmalone.id.au>
 */

'use strict';

const zlib = require( 'zlib' ),
      winston = require( 'winston' ),
      papertrailTransport = require( 'winston-papertrail' ).Papertrail;

const config = require( './env.json' );

exports.handler = ( event, context, callback ) => {
  context.callbackWaitsForEmptyEventLoop = config.waitForFlush;

  const payload = Buffer.from( event.awslogs.data, 'base64' );

  zlib.gunzip( payload, ( error, result ) => {
    if ( error ) return callback( error );

    const log = new ( winston.Logger )({
      transports: []
    });

    const data = JSON.parse( result.toString( 'utf8' ) );

    if ( config.debug ) console.log( data );

    log.add( papertrailTransport, {

      host:         config.papertrailHost,
      port:         config.papertrailPort,
      hostname:     config.lambdaName,
      program:      data.logGroup || config.logGroup,
      flushOnClose: true,

      logFormat: ( level, message ) => {
        return message;
      }

    });

    data.logEvents.forEach( ( line ) => {
      if ( config.debug ) console.log( line.message );
      log.info( line.message );
    });

    log.close();
    return callback();

  }); // Gunzip.
}; // Exports.handler.
