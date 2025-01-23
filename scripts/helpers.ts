import { Contract, ContractFactory } from "ethers";
import { ethers } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import path from "path";
import fs from "fs";

// Interface definition
interface OutputShape {
  [key: string]: {
    contractAddress: string;
    abi: object;
  };
}

// Deployment dir
const __DEPLOYMENT__DIR__ = "deployments";
// Deployment file name
const __DEPLOYMENT__FILE__ = "deployment.json";

export async function deploy<T>(contractName: string, ...args: any[]) {
  // Get contract factory
  const contractFactory = (await ethers.getContractFactory(contractName)) as ContractFactory;
  // Deployment transaction
  const transaction = await contractFactory.deploy(...args);
  const deployment = await transaction.deployed();
  return deployment as unknown as T;
}

export async function getContractWithAddress<T>(address: string) {
  const abi = getAbiFromPath("WETH", "WETH.sol");
  // Get contract at
  const contractAt = await ethers.getContractAt(abi, address);
  return contractAt as T;
}

function getAbiFromPath(contractName: string, pathName: string = "/") {
  // File root
  const root = path.join(__dirname, "../artifacts/contracts", pathName, contractName.concat(".json"));
  // Read file
  const content = fs.readFileSync(root);
  // Stringify buffer, and then parse
  const str = content.toString();
  const result = JSON.parse(str);
  return result.abi;
}

export async function writeOutput<T>(hardhatEnv: HardhatRuntimeEnvironment, c: T, contractName: string, abiPathName: string = "/") {
  const concatenatedPath = path.join(__dirname, __DEPLOYMENT__DIR__);
  // Folder name should be same as network name
  const folderName = hardhatEnv.network.name;
  // Concatenate path and folder name
  const folderConcatName = path.join(concatenatedPath, folderName);
  // Check if folder exists
  const folderExists = fs.existsSync(folderConcatName);
  // If folder does not exist, then make it
  if (!folderExists) fs.mkdirSync(folderConcatName, { recursive: true });
  // File name
  const fileName = path.join(folderConcatName, __DEPLOYMENT__FILE__);
  const fileExists = fs.existsSync(fileName);
  // Get address
  const contractAddress = (c as Contract).address;
  // Create JSON object
  const value: OutputShape = {
    [contractName]: {
      contractAddress,
      abi: getAbiFromPath(contractName, abiPathName)
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
    const c: OutputShape = JSON.parse(str);
    // Write new content to file
    const newContent: OutputShape = { ...c, ...value };
    fs.writeFileSync(fileName, JSON.stringify(newContent, undefined, 2));
  }
}
