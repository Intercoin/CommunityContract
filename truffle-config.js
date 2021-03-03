/**
 * Use this file to configure your truffle project. It's seeded with some
 * common settings for different networks and features like migrations,
 * compilation and testing. Uncomment the ones you need or modify
 * them to suit your project as necessary.
 *
 * More information about configuration can be found at:
 *
 * truffleframework.com/docs/advanced/configuration
 *
 * To deploy via Infura you'll need a wallet provider (like @truffle/hdwallet-provider)
 * to sign your transactions before they're sent to a remote public node. Infura accounts
 * are available for free at: infura.io/register.
 *
 * You'll also need a mnemonic - the twelve word phrase the wallet uses to generate
 * public/private key pairs. If you're publishing your code to GitHub make sure you load this
 * phrase from a file you've .gitignored so it doesn't accidentally become public.
 *
 */

// const HDWalletProvider = require('@truffle/hdwallet-provider');
// const infuraKey = "fj4jll3k.....";
//
// const fs = require('fs');
// const mnemonic = fs.readFileSync(".secret").toString().trim();

const HDWalletProvider = require("@truffle/hdwallet-provider");
 
const mnemonicPhrase = "mountains supernatural bird accidentally phrase generate command specific development parity this network_id";

module.exports = {
    
  /**
   * Networks define how you connect to your ethereum client and let you set the
   * defaults web3 uses to send transactions. If you don't specify one truffle
   * will spin up a development blockchain for you on port 9545 when you
   * run `develop` or `test`. You can ask a truffle command to use a specific
   * network from the command line, e.g
   *
   * $ truffle test --network <network-name>
   */

  networks: {
    // Useful for testing. The `development` name is special - truffle uses it by default
    // if it's defined here and no other network is specified at the command line.
    // You should run a client (like ganache-cli, geth or parity) in a separate terminal
    // tab if you use this network and you must also set the `host`, `port` and `network_id`
    // options below to some value.
    //-----------------------------------------------------
    // ganache-cli --gasLimit 8000000 --account "0xbde48e940a420314a923b9714be791b3d7917b186a7acd6bc0fabbd94016e980,300000000000000000000" --account "0xd18dff433755e36145ed20c6d17e080b38ee1de8cf03c1d9acddce03e6a46748,300000000000000000000" --account "0xa0d7b221b8036514d20a4b5a0c1505a3e8aa56912f0815d3b51ee67ab5552f93,300000000000000000000" --account "0xc2f4d2258f78db18163b4c87230fc8e2a1d76b9a1e2320c8477b04c86d64a7d4,300000000000000000000" --account "0x08c34c33a419667207ac459cd6ce36da4eecd575c262930804aff2c5988f6278,300000000000000000000" --account "0xd655ec94440153972b071ea2caa869e732e3fe37c5d861d6251ede95de7860a2,300000000000000000000" --account "0x6232bc892200550c70118d520c8f1800ef77577ff58504990a2f36f321fddc80,300000000000000000000" --account "0xefbfd07fc3c849999bda3528ac384d37ccf5f60993803643b1b29c533ef5bfbf,300000000000000000000" --account "0x129f914e38176b67ac29ef6a2d604a48de31853b4c2fe01536a4ab6984d4b737,300000000000000000000" --account "0xb0bd2ecde7fc54857d883808cd557fe9791a40cee99fec61f80c0ac5224f60d0,300000000000000000000"
    development: {
     host: "127.0.0.1",     // Localhost (default: none)
     port: 8545,            // Standard Ethereum port (default: none)
     network_id: "*",       // Any network (default: none)
     gas: 9000000
    },
    // Another network with more advanced options...
    // advanced: {
    // port: 8777,             // Custom port
    // network_id: 1342,       // Custom network
    // gas: 8500000,           // Gas sent with each transaction (default: ~6700000)
    // gasPrice: 20000000000,  // 20 gwei (in wei) (default: 100 gwei)
    // from: <address>,        // Account to send txs from (default: accounts[0])
    // websockets: true        // Enable EventEmitter interface for web3 (default: false)
    // },
    // Useful for deploying to a public network.
    // NB: It's important to wrap the provider as a function.
    // ropsten: {
    // provider: () => new HDWalletProvider(mnemonic, `https://ropsten.infura.io/v3/YOUR-PROJECT-ID`),
    // network_id: 3,       // Ropsten's id
    // gas: 5500000,        // Ropsten has a lower block limit than mainnet
    // confirmations: 2,    // # of confs to wait between deployments. (default: 0)
    // timeoutBlocks: 200,  // # of blocks before a deployment times out  (minimum/default: 50)
    // skipDryRun: true     // Skip dry run before migrations? (default: false for public nets )
    // },
    // Useful for private networks
    // private: {
    // provider: () => new HDWalletProvider(mnemonic, `https://network.io`),
    // network_id: 2111,   // This network is yours, in the cloud.
    // production: true    // Treats this network as if it was a public net. (default: false)
    // }
  },

  // Set default mocha options here, use special reporters etc.
  mocha: {
    // timeout: 100000
  },

  // Configure your compilers
  compilers: {
    solc: {
      version: "0.6.2",    // Fetch exact version from solc-bin (default: truffle's version)
      // docker: true,        // Use "0.5.1" you've installed locally with docker (default: false)
      settings: {          // See the solidity docs for advice about optimization and evmVersion
        optimizer: {
          enabled: true,
          runs: 200
        },
      //  evmVersion: "byzantium"
      }
    },
  },
};
