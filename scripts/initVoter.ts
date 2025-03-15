import fs from "fs";
import path from "path";
import hardhat from "hardhat";
import { PermissionsRegistry, Voter } from "../artifacts/types";
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

async function setVoterAdminAndInit() {
  // Deployments
  const deployments = readSimplifiedDeployments();
  // Get permissions registry
  const prg = await getContractWithAddress<PermissionsRegistry>(deployments.PermissionsRegistry, "PermissionsRegistry", "PermissionsRegistry.sol");
  await prg.setRoleFor("0xb69DB7b7B3aD64d53126DCD1f4D5fBDaea4fF578", "VOTER_ADMIN");
  // Get voter
  const voter = await getContractWithAddress<Voter>(deployments.Voter, "Voter", "Voter.sol");
  await voter._init(
    [
      "0x4Ba2ca8F076a8a9A9166d4CB4cCa86f42918a8e6",
      "0x400883e03aAAE5Eb1dE4273B602c067F8F1E252D",
      "0x760AfE86e5de5fa0Ee542fc7B7B713e1c5425701",
      "0xf817257fed379853cDe0fa4F97AB987181B1E5Ea",
      "0x88b8E2161DEDC77EF4ab7585569D2415a1C1055D"
    ],
    deployments.PermissionsRegistry,
    deployments.MinterUpgradeable
  );
}

setVoterAdminAndInit()
  .then(() => {
    console.log("Admin set for voter!");
  })
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
