import hardhat from "hardhat";
import { RewardHelper, VeNFTHelper } from "../../artifacts/types";
import { deploy, writeOutput } from "../helpers";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import path from "path";
import fs from "fs";

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

async function main() {
  console.log("Deployment initialized for: ", hardhat.network.name);
  // Get deployments
  const deployments = readDeploymentsOutput(hardhat);
  // Deploy reward helper
  const rewardHelper = await deploy<RewardHelper>("RewardHelper");
  await writeOutput(hardhat, rewardHelper, "RewardHelper", "api/RewardHelper.sol");
  await rewardHelper.initialize(deployments.Voter.contractAddress);
  // Deploy veNFT helper
  const veNFTHelper = await deploy<VeNFTHelper>("veNFTHelper");
  await writeOutput(hardhat, veNFTHelper, "veNFTHelper", "api/veNFTHelper.sol");
  await veNFTHelper.initialize(
    deployments.Voter.contractAddress,
    deployments.RewardsDistributor.contractAddress,
    deployments.PairHelper.contractAddress
  );
}

main()
  .then(() => {
    console.log("Deployments complete!!!");
  })
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
