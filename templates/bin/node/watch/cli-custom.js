#!/usr/bin/env node

const argv = require('minimist')(process.argv.slice(2));
const execshell = require('exec-sh');
const cp = require('child_process');
const path = require('path');
const watch = require('./main.js');
const ws = require('ws');


if (argv._.length === 0) {
  console.error([
    'Usage: watch <command> [...directory]',
    '[--wait=<seconds>]',
    '[--filter=<file>]',
    '[--interval=<seconds>]',
    '[--ignoreDotFiles]',
    '[--ignoreUnreadable]',
    '[--ignoreDirectoryPattern]',
    '[--exit]'
  ].join(' '));
  process.exit();
}

let command = argv._[0];
const watchTreeOpts = {};
const dirs = [];

let reloadCommand = null;
let wsServer = null;
let firstRun = true;

// Only start the websocket server for the html5 target.
if (command.endsWith(' -html5-reload')) {
  useWebSocket = true;
  command = command.replace(/ -html5-reload$/, '');

	// Change `lime [run or test] html5` to `lime build html5` as command to run when files change.
  reloadCommand = command.replace(/(run|test) html5/, 'build html5')
  wsServer = new ws.WebSocketServer({ port: 8080 });
}

const argLen = argv._.length
if (argLen > 1) {
  for(let i = 1; i< argLen; i++) {
      dirs.push(argv._[i])
  }
} else {
  dirs.push(process.cwd())
}

const waitTime = Number(argv.wait || argv.w)
if (argv.interval || argv.i) {
  watchTreeOpts.interval = Number(argv.interval || argv.i || 0.2);
}

const exitShell = (argv.exit || argv.e);

if(argv.ignoreDotFiles || argv.d)
  watchTreeOpts.ignoreDotFiles = true;

if(argv.ignoreUnreadable || argv.u)
  watchTreeOpts.ignoreUnreadableDir = true;

if(argv.ignoreDirectoryPattern || argv.p) {
  const match = (argv.ignoreDirectoryPattern || argv.p).match(/^\/(.*)\/([gimuy]*)$/);
  watchTreeOpts.ignoreDirectoryPattern = new RegExp(match[1], match[2]);
}

if(argv.filter || argv.f) {
  try {
    watchTreeOpts.filter = require(path.resolve(process.cwd(), argv.filter || argv.f));
  } catch (e) {
    console.error(e);
    process.exit(1);
  }
}

watchTreeOpts.filter = (file, stat) => {
	const ext = path.extname(file);
	return (ext == "" || ext == ".hx");
};

let wait = false;
let shell = null;

const dirLen = dirs.length;
let skip = dirLen - 1;
for(let i = 0; i < dirLen; i++) {
  const dir = dirs[i];
  console.error('> Watching', dir);
  watch.watchTree(dir, watchTreeOpts, (f, curr, prev) => {
    if(skip) {
        skip--;
        return;
    }
    if(wait) return;

    if(exitShell && shell != null) {
      try {
        var isWin = /^win/.test(process.platform);
        if(!isWin) {
            shell.kill('SIGKILL');
        } else {
            cp.exec('taskkill /PID ' + shell.pid + ' /T /F', (error, stdout, stderr) => {
            });
        }
      } catch (e) {}
    }
    try {
      console.error('> Rebuilding...');

      if (wsServer) {
				// The first time run the original command to start the web server.
        if (firstRun) {
          firstRun = false;
          shell = execshell(command);
        } else {
					// Run build and then send a reload command to the browser when the build in complete.
          shell = execshell(reloadCommand, undefined, (err) => {
            if (err) {
              console.error('Error during build:', err);
            } else {
              wsServer.clients.forEach(client => {
                if (client.readyState === ws.OPEN) {
                  client.send('reload');
                }
              });
            }
          });
        }
      } else {
        shell = execshell(command);
      }
    } catch (e) {
      console.error (e);
    }

    if(waitTime > 0) {
      wait = true;
      setTimeout(() => {
        wait = false;
      }, waitTime * 1000)
    }
  })
}
