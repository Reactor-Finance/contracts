import { deploy, writeOutput } from "../helpers";
import { VoterActionsSingleton } from "../../artifacts/types";
import hardhat from "hardhat";
import { __CONSTANTS__ } from "../constants";
import path from "path";
import fs from "fs";

const _DEPLOYMENTS_PATH = path.join(__dirname, "../simplifiedDeployments");

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

async function main() {
  console.log("Deployment initialized for: ", hardhat.network.name);
  // Outputs
  const output = readSimplifiedDeployments();
  // Deploy exchange helper
  const helper = await deploy<VoterActionsSingleton>("VoterActionsSingleton", output.veNFTHelper);
  await writeOutput(hardhat, helper, "VoterActionsSingleton", "VoterActionsSingleton.sol");
}

main()
  .then(() => {
    console.log("Deployments complete!!!");
  })
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
