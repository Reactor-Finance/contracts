import { HardhatRuntimeEnvironment } from "hardhat/types";
import path from "path";
import fs from "fs";
import hardhat from "hardhat";
import { getContractWithAddress } from "../helpers";
import { Pair, PairFactory } from "../../artifacts/types";

interface DeploymentsOutputShape {
  [key: string]: {
    contractAddress: string;
    abi: object;
  };
}

interface TokenShape {
  [key: string]: string;
}

interface PairsOutputShape {
  [key: string]: {
    token0: string;
    token1: string;
    name: string;
    symbol: string;
  };
}

interface TokensShape {
  [key: string]: string[];
}

// const weth: TokenShape = {
//   beraBartio: "0x7507c1dc16935B82698e4C63f2746A2fCf994dF8"
// };

const tokens: TokensShape = {
  beraBartio: [
    "0xd6D83aF58a19Cd14eF3CF6fe848C9A4d21e5727c",
    "0x05D0dD5135E3eF3aDE32a9eF9Cb06e8D37A6795D",
    "0x806Ef538b228844c73E8E692ADCFa8Eb2fCF729c"
  ],
  monadDevnet: ["0xA4A30ca987ee3e9de0b2dAca60C37e5E7e4EDa9D"]
};

function readDeploymentsOutput(hardhatEnv: HardhatRuntimeEnvironment) {
  // Network
  const network = hardhatEnv.network.name;
  // File root
  const root = path.join(__dirname, "../deployments", network, "deployment.json");
  // Read file
  const content = fs.readFileSync(root);
  // Stringify buffer, and then parse
  const str = content.toString();
  const result: DeploymentsOutputShape = JSON.parse(str);
  return result;
}

export async function writeOutput(
  hardhatEnv: HardhatRuntimeEnvironment,
  contractAddress: string,
  token0: string,
  token1: string,
  name: string,
  symbol: string
) {
  const concatenatedPath = path.join(__dirname, "../deployments");
  // Folder name should be same as network name
  const folderName = hardhatEnv.network.name;
  // Concatenate path and folder name
  const folderConcatName = path.join(concatenatedPath, folderName);
  // Check if folder exists
  const folderExists = fs.existsSync(folderConcatName);
  // If folder does not exist, then make it
  if (!folderExists) fs.mkdirSync(folderConcatName, { recursive: true });
  // File name
  const fileName = path.join(folderConcatName, "pairs.json");
  const fileExists = fs.existsSync(fileName);
  // Create JSON object
  const value: PairsOutputShape = {
    [contractAddress]: {
      token0,
      token1,
      name,
      symbol
    }
  };
  // Make file if it doesn't exist
  if (!fileExists) {
    const ws = fs.createWriteStream(fileName);
    // Write first JSON object to the file
    ws.write(JSON.stringify(value, undefined, 2));
    ws.end(); // End write stream
  } else {
    // Read file content
    const content = fs.readFileSync(fileName);
    // Stringify, and parse
    const str = content.toString();
    const c: PairsOutputShape = JSON.parse(str);
    // Write new content to file
    const newContent: PairsOutputShape = { ...c, ...value };
    fs.writeFileSync(fileName, JSON.stringify(newContent, undefined, 2));
  }
}

async function main() {
  // Get deployments
  const deployments = readDeploymentsOutput(hardhat);
  // Factory address
  const factory = deployments.PairFactory.contractAddress;
  // Reactor address
  const rct = deployments.Reactor.contractAddress;
  // WETH
  const eth = deployments.WETH.contractAddress;
  // Factory contract
  const fc = await getContractWithAddress<PairFactory>(factory, "PairFactory", "factories/PairFactory.sol");
  // Create RCT/WETH pair
  await fc.createPair(rct, eth, false); // Volatile pair
  // Get RCT/WETH pair address
  const rct_weth_addr = await fc.allPairs(0);
  // Get pair contract
  const rct_weth = await getContractWithAddress<Pair>(rct_weth_addr, "Pair", "Pair.sol");

  // Details
  const _rct_weth_token0 = await rct_weth.token0();
  const _rct_weth_token1 = await rct_weth.token1();
  const _rct_weth_name = await rct_weth.name();
  const _rct_weth_symbol = await rct_weth.symbol();

  await writeOutput(hardhat, rct_weth_addr, _rct_weth_token0, _rct_weth_token1, _rct_weth_name, _rct_weth_symbol);

  // Get tokens
  const _tokens = tokens[hardhat.network.name];

  // RCT pairs
  for (let i = 0; i < _tokens.length; i++) {
    const _token = _tokens[i];
    await fc.createPair(rct, _token, false); // Volatile pair
    // Fetch pairs
    let _pairs = await fc.pairs();
    // Last created pair
    let _pair = _pairs[_pairs.length - 1];
    // Pair contract
    let _pair_contract = await getContractWithAddress<Pair>(_pair, "Pair", "Pair.sol");

    // Details
    let _pair_token0 = await _pair_contract.token0();
    let _pair_token1 = await _pair_contract.token1();
    let _pair_name = await _pair_contract.name();
    let _pair_symbol = await _pair_contract.symbol();

    await writeOutput(hardhat, _pair, _pair_token0, _pair_token1, _pair_name, _pair_symbol);

    await fc.createPair(rct, _token, true); // Stable pair
    // Fetch pairs
    _pairs = await fc.pairs();
    // Last created pair
    _pair = _pairs[_pairs.length - 1];
    // Pair contract
    _pair_contract = await getContractWithAddress<Pair>(_pair, "Pair", "Pair.sol");

    // Details
    _pair_token0 = await _pair_contract.token0();
    _pair_token1 = await _pair_contract.token1();
    _pair_name = await _pair_contract.name();
    _pair_symbol = await _pair_contract.symbol();

    await writeOutput(hardhat, _pair, _pair_token0, _pair_token1, _pair_name, _pair_symbol);
  }

  // WETH pairs
  for (let i = 0; i < _tokens.length; i++) {
    const _token = _tokens[i];
    await fc.createPair(eth, _token, false); // Volatile pair
    // Fetch pairs
    let _pairs = await fc.pairs();
    // Last created pair
    let _pair = _pairs[_pairs.length - 1];
    // Pair contract
    let _pair_contract = await getContractWithAddress<Pair>(_pair, "Pair", "Pair.sol");

    // Details
    let _pair_token0 = await _pair_contract.token0();
    let _pair_token1 = await _pair_contract.token1();
    let _pair_name = await _pair_contract.name();
    let _pair_symbol = await _pair_contract.symbol();

    await writeOutput(hardhat, _pair, _pair_token0, _pair_token1, _pair_name, _pair_symbol);

    await fc.createPair(eth, _token, true); // Stable pair
    // Fetch pairs
    _pairs = await fc.pairs();
    // Last created pair
    _pair = _pairs[_pairs.length - 1];
    // Pair contract
    _pair_contract = await getContractWithAddress<Pair>(_pair, "Pair", "Pair.sol");

    // Details
    _pair_token0 = await _pair_contract.token0();
    _pair_token1 = await _pair_contract.token1();
    _pair_name = await _pair_contract.name();
    _pair_symbol = await _pair_contract.symbol();

    await writeOutput(hardhat, _pair, _pair_token0, _pair_token1, _pair_name, _pair_symbol);
  }
}

main()
  .then(() => {
    console.log("Pairs created!!!");
  })
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
