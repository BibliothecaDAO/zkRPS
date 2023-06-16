const starknet = require('micro-starknet');
const yargs = require('yargs/yargs');
const { hideBin } = require('yargs/helpers');

const argv = yargs(hideBin(process.argv)).argv;

console.log('Your commit hash is: ', starknet.poseidonHashMany([BigInt(argv.secret), BigInt(argv.move)]).toString());
console.log('Your secret is: ', argv.secret);
console.log('Your move is: ', argv.move);