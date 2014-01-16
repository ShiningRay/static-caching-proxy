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
    watch: {
      coffee: {
        files: ['server/**/*.coffee'],
        tasks: ['coffee:debug', 'mochaTest:test']
      },
      test: {
        files: ['test/**'],
        tasks: ['mochaTest:test']
      },
      gruntfile: {
        files: ['Gruntfile.js']
      }
    },
    clean: {
      dist: {
        files: [{
          dot: true,
          src: [
            'dist'
          ]
        }]
      }
    },
    coffee: {
      options: {
        sourceMap: true,
        bare: true
      },
      dist: {
        options: {
          sourceMap: false,
          bare: true
        },
        files: [{
          expand: true,
          cwd: 'server/',
          src: '**/*.coffee',
          dest: 'dist',
          ext: '.js'
        }]
      },
      debug: {
        options: {
          sourceMap: true,
          bare: true
        },
        files: [{
          expand: true,
          cwd: 'server/',
          src: '**/*.coffee',
          dest: 'dist',
          ext: '.js'
        }]
      }
    },
    nodemon: {
      debug: {
        options: {
          file: 'dist/index.js',
          nodeArgs: ['--debug'],
          ignoredFiles: ['node_modules/**', 'test/**'],
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
        tasks: ['nodemon:debug', 'node-inspector:debug', 'open:debug', 'wait:postDebug', 'open:dev', 'watch'],
        options: {
          logConcurrentOutput: true
        }
      }
    },
    mochaTest: {
      test: {
        options: {
          reporter: 'spec',
          // Require blanket wrapper here to instrument other required
          // files on the fly.
          //
          // NB. We cannot require blanket directly as it
          // detects that we are not running mocha cli and loads differently.
          //
          // NNB. As mocha is 'clever' enough to only run the tests once for
          // each file the following coverage task does not actually run any
          // tests which is why the coverage instrumentation has to be done here
          require: ['coffee-script', 'should', 'assert']
        },
        src: ['test/**/*.coffee']
      }
    }
  });

  grunt.loadNpmTasks('grunt-nodemon');
  grunt.loadNpmTasks('grunt-node-inspector');
  grunt.loadNpmTasks('grunt-concurrent');
  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('grunt-open');
  grunt.loadNpmTasks('grunt-wait');
  grunt.loadNpmTasks('grunt-contrib-coffee');
  grunt.loadNpmTasks('grunt-mocha-test');

  grunt.registerTask('default',
    ['coffee:debug', 'mochaTest:test', 'concurrent:debug']);

};

