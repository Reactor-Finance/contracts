import fs from "fs";
import path from "path";
import hardhat from "hardhat";
import { VotingEscrow } from "../artifacts/types";
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

async function setVoter() {
  // Deployments
  const deployments = readSimplifiedDeployments();

  // Get factory
  const helper = await getContractWithAddress<VotingEscrow>(deployments.VotingEscrow, "VotingEscrow", "VotingEscrow.sol");
  await helper.setVoter(deployments.Voter);
}

setVoter()
  .then(() => {
    console.log("setVoter!");
  })
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
