import { deploy, getContractWithAddress, writeOutput } from "../helpers";
import {
  BribeFactory,
  GaugeFactory,
  MinterUpgradeable,
  Oracle,
  Pair,
  PairFactory,
  PairHelper,
  PermissionsRegistry,
  Reactor,
  RewardHelper,
  RewardsDistributor,
  Router,
  TradeHelper,
  VeArtProxyUpgradeable,
  VeNFTHelper,
  Voter,
  VotingEscrow,
  WETH
} from "../../artifacts/types";
import hardhat from "hardhat";
import { __CONSTANTS__ } from "../constants";

async function main() {
  console.log("Deployment initialized for: ", hardhat.network.name);
  // ***** Core Contracts *****

  // Get shape
  const shape = __CONSTANTS__[hardhat.network.name];
  // Deploy Reactor
  const rct = await deploy<Reactor>("Reactor");
  await writeOutput(hardhat, rct, "Reactor", "Reactor.sol");
  // Mint RCT
  await rct.mint("0xb69DB7b7B3aD64d53126DCD1f4D5fBDaea4fF578", 5_00_000_000_000_000_000_000_000_000n);
  // Deploy weth
  let weth: WETH;
  // Deploy if not a string
  if (typeof shape.wrappedEther !== "string") {
    weth = await deploy<WETH>("WETH", shape.wrappedEther.name, shape.wrappedEther.symbol);
    await writeOutput(hardhat, weth, "WETH", "WETH.sol");
  } else {
    weth = await getContractWithAddress<WETH>(shape.wrappedEther, "WETH", "WETH.sol");
    await writeOutput(hardhat, weth, "WETH", "WETH.sol");
  }
  // Deploy permissions registry
  const prg = await deploy<PermissionsRegistry>("PermissionsRegistry");
  await writeOutput(hardhat, prg, "PermissionsRegistry", "PermissionsRegistry.sol");
  // Set admin roles
  await prg.setRoleFor("0xb69DB7b7B3aD64d53126DCD1f4D5fBDaea4fF578", "VOTER_ADMIN");
  await prg.setRoleFor("0xb69DB7b7B3aD64d53126DCD1f4D5fBDaea4fF578", "BRIBE_ADMIN");
  await prg.setRoleFor("0xb69DB7b7B3aD64d53126DCD1f4D5fBDaea4fF578", "GAUGE_ADMIN");
  await prg.setRoleFor("0xb69DB7b7B3aD64d53126DCD1f4D5fBDaea4fF578", "GOVERNANCE");
  await prg.setRoleFor("0xb69DB7b7B3aD64d53126DCD1f4D5fBDaea4fF578", "FEE_MANAGER");
  // Deploy pair implementation
  const pair = await deploy<Pair>("Pair");
  const impl = pair.address;
  // Deploy pair factory
  const pairFactory = await deploy<PairFactory>("PairFactory", impl);
  await writeOutput(hardhat, pairFactory, "PairFactory", "factories/PairFactory.sol");
  // Deploy gauge factory
  const gaugeFactory = await deploy<GaugeFactory>("GaugeFactory");
  await writeOutput(hardhat, gaugeFactory, "GaugeFactory", "factories/GaugeFactory.sol");
  // Initialize gauge factory with permissions registry
  await gaugeFactory.initialize(prg.address);
  // Deploy art proxy
  const artProxy = await deploy<VeArtProxyUpgradeable>("VeArtProxyUpgradeable");
  await writeOutput(hardhat, artProxy, "VeArtProxyUpgradeable", "VeArtProxyUpgradeable.sol");
  // Initialize art proxy
  await artProxy.initialize();
  // Deploy voting escrow
  const votingEscrow = await deploy<VotingEscrow>("VotingEscrow", rct.address, artProxy.address);
  await writeOutput(hardhat, votingEscrow as any, "VotingEscrow", "VotingEscrow.sol");
  // Deploy voter
  const voter = await deploy<Voter>("Voter");
  await writeOutput(hardhat, voter, "Voter", "Voter.sol");
  // Deploy bribe factory
  const bribeFactory = await deploy<BribeFactory>("BribeFactory");
  await writeOutput(hardhat, bribeFactory, "BribeFactory", "factories/BribeFactory.sol");
  // Initialize bribe factory, and voter
  await bribeFactory.initialize(voter.address, prg.address, [...shape.defaultRewardTokens, weth.address, rct.address]);
  await voter.initialize(votingEscrow.address, pairFactory.address, gaugeFactory.address, bribeFactory.address);
  // Deploy rewards distributor
  const rewardsDistributor = await deploy<RewardsDistributor>("RewardsDistributor", votingEscrow.address);
  await writeOutput(hardhat, rewardsDistributor, "RewardsDistributor", "RewardsDistributor.sol");
  // Deploy minter
  const minter = await deploy<MinterUpgradeable>("MinterUpgradeable");
  await writeOutput(hardhat, minter, "MinterUpgradeable", "MinterUpgradeable.sol");
  // Initialize minter
  await minter.initialize(voter.address, votingEscrow.address, rewardsDistributor.address);
  // Set RCT minter
  await rct.setMinter(minter.address);
  // Mint initial
  await minter._initialize(shape.initialMintRecipients, shape.initialMintAmounts, BigInt(100_000_000 * 1e18));
  await voter._init(
    [
      "0x4Ba2ca8F076a8a9A9166d4CB4cCa86f42918a8e6",
      "0x400883e03aAAE5Eb1dE4273B602c067F8F1E252D",
      "0x760AfE86e5de5fa0Ee542fc7B7B713e1c5425701",
      "0xf817257fed379853cDe0fa4F97AB987181B1E5Ea",
      "0x88b8E2161DEDC77EF4ab7585569D2415a1C1055D"
    ],
    prg.address,
    minter.address
  );

  // ***** Trading *****
  // Deploy trade helper
  const tradeHelper = await deploy<TradeHelper>("TradeHelper", pairFactory.address);
  await writeOutput(hardhat, tradeHelper, "TradeHelper", "api/TradeHelper.sol");
  // Deploy router
  const router = await deploy<Router>("Router", tradeHelper.address, weth.address);
  await writeOutput(hardhat, router, "Router", "Router.sol");

  // ***** Other APIs *****
  // Deploy pair helper
  const pairHelper = await deploy<PairHelper>("PairHelper");
  await writeOutput(hardhat, pairHelper, "PairHelper", "api/PairHelper.sol");
  await pairHelper.initialize(voter.address);
  // Deploy reward helper
  const rewardHelper = await deploy<RewardHelper>("RewardHelper");
  await writeOutput(hardhat, rewardHelper, "RewardHelper", "api/RewardHelper.sol");
  await rewardHelper.initialize(voter.address);
  // Deploy veNFT helper
  const veNFTHelper = await deploy<VeNFTHelper>("veNFTHelper");
  await writeOutput(hardhat, veNFTHelper, "veNFTHelper", "api/veNFTHelper.sol");
  await veNFTHelper.initialize(voter.address, rewardsDistributor.address, pairHelper.address);
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
