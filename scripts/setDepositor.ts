import fs from "fs";
import path from "path";
import hardhat from "hardhat";
import { RewardsDistributor } from "../artifacts/types";
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

async function setDepositor() {
  // Deployments
  const deployments = readSimplifiedDeployments();
  // Get factory
  const distributor = await getContractWithAddress<RewardsDistributor>(
    deployments.RewardsDistributor,
    "RewardsDistributor",
    "RewardsDistributor.sol"
  );
  await distributor.setDepositor(deployments.MinterUpgradeable);
}

setDepositor()
  .then(() => {
    console.log("Set depositor!");
  })
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
