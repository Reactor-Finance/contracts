import fs from "fs";
import path from "path";
import hardhat from "hardhat";
import type { HardhatRuntimeEnvironment } from "hardhat/types";
import { deploy, writeOutput } from "../helpers";
import { Router } from "../../artifacts/types";

interface DeploymentsOutputShape {
  [key: string]: {
    contractAddress: string;
    abi: object;
  };
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

async function deployRouter() {
  // Read deployments output
  const output = readDeploymentsOutput(hardhat);
  const router = await deploy<Router>("Router", output.TradeHelper.contractAddress, output.WETH.contractAddress);
  await writeOutput(hardhat, router, "Router", "Router.sol");
}

deployRouter()
  .then(() => {
    console.log("Deploy router!!");
  })
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
