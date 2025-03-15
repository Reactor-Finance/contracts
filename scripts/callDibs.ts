import fs from "fs";
import path from "path";
import hardhat from "hardhat";
import { PairFactory } from "../artifacts/types";
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

async function callDibs() {
  // Deployments
  const deployments = readSimplifiedDeployments();
  // Get factory
  const pairFactory = await getContractWithAddress<PairFactory>(deployments.PairFactory, "PairFactory", "factories/PairFactory.sol");
  await pairFactory.setDibs("0xb69DB7b7B3aD64d53126DCD1f4D5fBDaea4fF578");
}

callDibs()
  .then(() => {
    console.log("Called dibs!");
  })
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
