import fs from "fs";
import path from "path";
import hardhat from "hardhat";
import { ExchangeHelper } from "../artifacts/types";
import { getContractWithAddress } from "./helpers";

const _DEPLOYMENTS_PATH = path.join(__dirname, "simplifiedDeployments");

interface DeploymentsShape {
  [key: string]: string;
}

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

async function getTVL() {
  // Deployments
  const deployments = readSimplifiedDeployments();

  // Get factory
  const helper = await getContractWithAddress<ExchangeHelper>(deployments.ExchangeHelper, "ExchangeHelper", "api/ExchangeHelper.sol");
  const bn0 = await helper.getTVLInUSDForPair("0xEa1ab6291C8d19F74565831A9Fd63A5f339ec1E3");
  console.log(bn0.toString());
  const bn = await helper.getTVLInUSDForAllPairs();
  console.log(bn.toString());
}

getTVL()
  .then(() => {
    console.log("TVL!");
  })
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
