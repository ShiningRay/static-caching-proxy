// Generated on 2014-01-06 using generator-nodeapp 0.0.1
'use strict';

var host = 'localhost';
var serverPorts = {
  client: '8000',
  debug: '5858',
  inspector: '8080'
};

module.exports = function(grunt) {

  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),
    nodemon: {
      debug: {
        options: {
          file: 'server/index.js',
          nodeArgs: ['--debug'],
          ignoredFiles: ['node_modules/**'],
          env: {
            PORT: serverPorts.client
          }
        }
      }
    },
    'node-inspector': {
      debug: {
        options: {
          'web-port': serverPorts.inspector,
          'web-host': host,
          'debug-port': serverPorts.debug,
          'save-live-edit': true
        }
      }
    },
    open : {
      debug: {
        path: 'http://' + host + ':' + serverPorts.inspector + '/debug?port=' + serverPorts.debug,
        app: 'Google Chrome'
      },
      dev : {
        path: 'http://' + host + ':' + serverPorts.client,
        app: 'Google Chrome'
      }
    },
    wait: {
      postDebug: {
        options: {
          delay: 100,
        }
      }
    },
    concurrent: {
      debug: {
        tasks: ['nodemon:debug', 'node-inspector:debug', 'open:debug', 'wait:postDebug', 'open:dev'],
        options: {
          logConcurrentOutput: true
        }
      }
    }
  });

  grunt.loadNpmTasks('grunt-nodemon');
  grunt.loadNpmTasks('grunt-node-inspector');
  grunt.loadNpmTasks('grunt-concurrent');
  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('grunt-open');
  grunt.loadNpmTasks('grunt-wait');

  grunt.registerTask('default', ['concurrent:debug']);

};

