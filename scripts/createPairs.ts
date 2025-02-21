import fs from "fs";
import path from "path";
import hardhat from "hardhat";
import { Pair, PairFactory } from "../artifacts/types";
import { getContractWithAddress } from "./helpers";

const _DEPLOYMENTS_PATH = path.join(__dirname, "simplifiedDeployments");

interface DeploymentsShape {
  [key: string]: string;
}

interface PairsOutputShape {
  [pairSymbol: string]: string;
}

// USDC_&_USDT
const USDC: { [key: string]: string } = {
  monadTestnet: "0x62534E4bBD6D9ebAC0ac99aeaa0aa48E56372df0"
};
const USDT: { [key: string]: string } = {
  monadTestnet: "0x88b8E2161DEDC77EF4ab7585569D2415a1C1055D"
};

// WETH
const WETH: { [key: string]: string } = {
  monadTestnet: "0x760AfE86e5de5fa0Ee542fc7B7B713e1c5425701"
};

function readSimplifiedDeployments() {
  // Network name
  const networkName = hardhat.network.name;
  // Full file path
  const fullPath = path.join(_DEPLOYMENTS_PATH, networkName, "index.json");
  // Read content
  const content = fs.readFileSync(fullPath);
  // Stringify, and parse
  const shape: DeploymentsShape = JSON.parse(content.toString());
  // Get factory
  return shape;
}

async function writeOutput(pairFactory: PairFactory) {
  // Get pairs
  const pairs = await pairFactory.pairs();
  // Output
  const output: PairsOutputShape = {};
  // Run for each pair
  await Promise.all(
    pairs.map(async (address) => {
      const pair = await getContractWithAddress<Pair>(address, "Pair", "Pair.sol");
      const symbol = await pair.symbol();
      output[symbol] = address;
    })
  );

  // Network name
  const networkName = hardhat.network.name;
  // File name
  const fileName = path.join(_DEPLOYMENTS_PATH, networkName, "pairs.json");
  // Check that file exists
  if (!fs.existsSync(fileName)) {
    const ws = fs.createWriteStream(fileName);
    ws.write(JSON.stringify(output, undefined, 2));
    ws.end();
  } else {
    // Read existing file
    const content = fs.readFileSync(fileName);
    // Stringify and parse
    const out: PairsOutputShape = JSON.parse(content.toString());
    fs.writeFileSync(fileName, JSON.stringify({ ...out, ...output }, undefined, 2));
  }
}

async function createPairs() {
  // Deployments
  const deployments = readSimplifiedDeployments();
  // Network name
  const networkName = hardhat.network.name;
  // Get factory
  const pairFactory = await getContractWithAddress<PairFactory>(deployments.PairFactory, "PairFactory", "factories/PairFactory.sol");
  // Create pairs
  await Promise.allSettled([
    pairFactory.createPair(WETH[networkName], deployments.Reactor, false),
    pairFactory.createPair(WETH[networkName], USDC[networkName], false),
    pairFactory.createPair(WETH[networkName], USDT[networkName], false),
    pairFactory.createPair(deployments.Reactor, USDC[networkName], false),
    pairFactory.createPair(deployments.Reactor, USDT[networkName], false)
  ]);
  // Write output
  await writeOutput(pairFactory);
}

createPairs()
  .then(() => {
    console.log("Pairs created!");
  })
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
