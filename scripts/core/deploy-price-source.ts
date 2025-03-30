import { HardhatRuntimeEnvironment } from "hardhat/types";
import path from "path";
import fs from "fs";
import hardhat from "hardhat";
import { deploy, getContractWithAddress } from "../helpers";
import { Oracle, UniswapV2PriceSource } from "../../artifacts/types";
import { __CONSTANTS__ } from "../constants";

interface DeploymentsOutputShape {
  [key: string]: {
    contractAddress: string;
    abi: object;
  };
}

interface OutputShape {
  [key: string]: string;
}

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

export async function writeOutput(hardhatEnv: HardhatRuntimeEnvironment, name: string, address: string) {
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
  const fileName = path.join(folderConcatName, "priceSources.json");
  const fileExists = fs.existsSync(fileName);
  // Create JSON object
  const value: OutputShape = {
    [name]: address
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

async function main() {
  // Get deployments
  const deployments = readDeploymentsOutput(hardhat);
  // Shape
  const shape = __CONSTANTS__[hardhat.network.name];
  // Oracle contract
  const oracle = await getContractWithAddress<Oracle>(deployments.Oracle.contractAddress, "Oracle", "oracle/Oracle.sol");
  const uniswapV2PriceSource = await deploy<UniswapV2PriceSource>(
    "UniswapV2PriceSource",
    "0x733E88f248b742db6C14C0b1713Af5AD7fDd59D0",
    "0xfB8e1C3b833f9E67a71C859a132cf783b645e436",
    "0x88b8E2161DEDC77EF4ab7585569D2415a1C1055D",
    "0xf817257fed379853cDe0fa4F97AB987181B1E5Ea",
    shape.wrappedEther as string
  );
  const oraclePriceSources = await oracle.getAllPriceSources();
  await oracle.setPriceSources([...oraclePriceSources, uniswapV2PriceSource.address]);
}

main()
  .then(() => {
    console.log("Done!!!");
  })
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
