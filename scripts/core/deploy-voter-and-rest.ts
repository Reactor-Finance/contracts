import hardhat from "hardhat";
import {
  BribeFactory,
  MinterUpgradeable,
  Oracle,
  PairHelper,
  Reactor,
  RewardHelper,
  RewardsDistributor,
  Router,
  TradeHelper,
  VeNFTHelper,
  Voter
} from "../../artifacts/types";
import { deploy, getContractWithAddress, writeOutput } from "../helpers";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import path from "path";
import fs from "fs";
import { __CONSTANTS__ } from "../constants";

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
  // Get shape
  const shape = __CONSTANTS__[hardhat.network.name];
  // Get deployments
  const deployments = readDeploymentsOutput(hardhat);
  // Deploy bribe factory
  // const bribeFactory = await deploy<BribeFactory>("BribeFactory");
  // await writeOutput(hardhat, bribeFactory, "BribeFactory", "factories/BribeFactory.sol");
  // // Initialize bribe factory, and voter
  // await bribeFactory.initialize(deployments.Voter.contractAddress, deployments.PermissionsRegistry.contractAddress, [
  //   ...shape.defaultRewardTokens,
  //   shape.wrappedEther as string,
  //   deployments.Reactor.contractAddress
  // ]);
  // const voter = await getContractWithAddress<Voter>(deployments.Voter.contractAddress, "Voter", "Voter.sol");
  // await voter.initialize(
  //   deployments.VotingEscrow.contractAddress,
  //   deployments.PairFactory.contractAddress,
  //   deployments.GaugeFactory.contractAddress,
  //   bribeFactory.address
  // );
  // // Deploy rewards distributor
  // const rewardsDistributor = await deploy<RewardsDistributor>("RewardsDistributor", deployments.VotingEscrow.contractAddress);
  // await writeOutput(hardhat, rewardsDistributor, "RewardsDistributor", "RewardsDistributor.sol");
  // // Deploy minter
  // const minter = await deploy<MinterUpgradeable>("MinterUpgradeable");
  // await writeOutput(hardhat, minter, "MinterUpgradeable", "MinterUpgradeable.sol");
  // // Initialize minter
  // await minter.initialize(voter.address, deployments.VotingEscrow.contractAddress, rewardsDistributor.address);
  // const rct = await getContractWithAddress<Reactor>(deployments.Reactor.contractAddress, "Reactor", "Reactor.sol");
  // // Set RCT minter
  // await rct.setMinter(minter.address);
  // // Mint initial
  // await minter._initialize(shape.initialMintRecipients, shape.initialMintAmounts, BigInt(100_000_000 * 1e18));

  // // ***** Trading *****
  // // Deploy trade helper
  // const tradeHelper = await deploy<TradeHelper>("TradeHelper", deployments.PairFactory.contractAddress);
  // await writeOutput(hardhat, tradeHelper, "TradeHelper", "api/TradeHelper.sol");
  // // Deploy router
  // const router = await deploy<Router>("Router", tradeHelper.address, shape.wrappedEther as string);
  // await writeOutput(hardhat, router, "Router", "Router.sol");

  // // ***** Other APIs *****
  // // Deploy pair helper
  // const pairHelper = await deploy<PairHelper>("PairHelper");
  // await writeOutput(hardhat, pairHelper, "PairHelper", "api/PairHelper.sol");
  // await pairHelper.initialize(voter.address);
  // // Deploy reward helper
  // const rewardHelper = await deploy<RewardHelper>("RewardHelper");
  // await writeOutput(hardhat, rewardHelper, "RewardHelper", "api/RewardHelper.sol");
  // await rewardHelper.initialize(voter.address);
  // Deploy veNFT helper
  const veNFTHelper = await deploy<VeNFTHelper>("veNFTHelper");
  await writeOutput(hardhat, veNFTHelper, "veNFTHelper", "api/veNFTHelper.sol");
  await veNFTHelper.initialize(
    deployments.Voter.contractAddress,
    deployments.RewardsDistributor.contractAddress,
    deployments.PairHelper.contractAddress
  );
  // Deploy oracle
  const oracle = await deploy<Oracle>("Oracle", []);
  await writeOutput(hardhat, oracle, "Oracle", "oracle/Oracle.sol");
}

main()
  .then(() => {
    console.log("Deployments complete!!!");
  })
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
