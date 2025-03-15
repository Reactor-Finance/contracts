import fs from "fs";
import path from "path";
import hardhat from "hardhat";

interface OutputShape {
  [key: string]: {
    contractAddress: string;
    abi: object;
  };
}

interface SimplifiedShape {
  [key: string]: string;
}

const deploymentsPath = path.join(__dirname, "deployments");
const simplifiedPath = path.join(__dirname, "simplifiedDeployments");

function readFromDeployment() {
  // Network name
  const networkName = hardhat.network.name;
  // Full path
  const fullPath = path.join(deploymentsPath, networkName, "deployment.json");
  // Read file
  const contentAsBuffer = fs.readFileSync(fullPath);
  // Stringify
  const contentAsString = contentAsBuffer.toString();
  // Parse
  const actualContent: OutputShape = JSON.parse(contentAsString);
  return actualContent;
}

function simplifyDeployments() {
  // Read
  const deploymentShape = readFromDeployment();
  // Check simplified path exists
  const pathExists = fs.existsSync(simplifiedPath);
  // Create folder if not exists
  if (!pathExists) fs.mkdirSync(simplifiedPath);
  // Path + network name
  const sPath = path.join(simplifiedPath, hardhat.network.name);
  if (!fs.existsSync(sPath)) fs.mkdirSync(sPath);
  // Read deployment shape, and persist to simplified folder
  // Simplified path
  const simplifiedDeployment = path.join(sPath, "index.json");
  const simplifiedValue: SimplifiedShape = {};
  // Mutate
  for (const key of Object.keys(deploymentShape)) {
    simplifiedValue[key] = deploymentShape[key].contractAddress;
  }
  // Save
  const ws = fs.createWriteStream(simplifiedDeployment);
  ws.write(JSON.stringify(simplifiedValue, undefined, 2));
  ws.end();

  // Create ABIs folder
  const abis = path.join(sPath, "abis");
  if (!fs.existsSync(abis)) fs.mkdirSync(abis);
  // Create ABI files
  for (const key of Object.keys(deploymentShape)) {
    // File name
    const fName = `${key}.abi.json`;
    const saveAs = path.join(abis, fName);
    const abi = deploymentShape[key].abi;
    // Save
    const iws = fs.createWriteStream(saveAs);
    iws.write(JSON.stringify(abi, undefined, 2));
    iws.end();
  }
}

simplifyDeployments();
