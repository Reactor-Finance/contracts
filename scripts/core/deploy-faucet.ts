import { deploy, writeOutput } from "../helpers";
import { Faucet, TokenDispenser } from "../../artifacts/types";
import hardhat from "hardhat";
import { __CONSTANTS__ } from "../constants";

async function main() {
  console.log("Deployment initialized for: ", hardhat.network.name);
  // Deploy token dispenser implementation
  const impl = await deploy<TokenDispenser>("TokenDispenser");
  // Deploy faucet
  const faucet = await deploy<Faucet>("Faucet", impl.address);
  await writeOutput(hardhat, faucet, "Faucet", "faucet/Faucet.sol");
  // Deploy ETH dispenser
  await faucet.deployDispenser(
    "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
    1_000_000_000_000_000_000n,
    "0xb69DB7b7B3aD64d53126DCD1f4D5fBDaea4fF578",
    86400
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
