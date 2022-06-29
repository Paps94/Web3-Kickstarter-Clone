const path = require("path");
const solc = require("solc");
const fs = require("fs-extra");

const campaignPath = path.resolve(__dirname, "contracts", "Campaign.sol"); //Read 'Capaign.sol' from the 'contracts' folder
const source = fs.readFileSync(campaignPath, "utf8");

// The last line of codes need to be changed like below.
const input = {
  language: "Solidity",
  sources: {
    "Campaign.sol": {
      content: source,
    },
  },
  settings: {
    outputSelection: {
      "*": {
        "*": ["*"],
      },
    },
  },
};

const output = JSON.parse(solc.compile(JSON.stringify(input)));
console.log(solc.compile(source, 1).contracts);
module.exports = {
  abi: output.contracts["Campaign.sol"].Campaign.abi,
  bytecode: output.contracts["Campaign.sol"].Campaign.evm.bytecode.object,
};
