#!/usr/bin/env node
const { spawnSync } = require('child_process');
const path = require('path');
const fs = require('fs');

const script = path.join(__dirname, '..', 'install.sh');
fs.chmodSync(script, 0o755);

const result = spawnSync('bash', [script, ...process.argv.slice(2)], {
  stdio: 'inherit',
});
process.exit(result.status ?? 1);
