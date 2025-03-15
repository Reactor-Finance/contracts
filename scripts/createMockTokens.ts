import fs from "fs";
import path from "path";
import hardhat from "hardhat";
import { MockERC20 } from "../artifacts/types";
import { deploy } from "./helpers";
import { parseEther } from "ethers/lib/utils";

const _DEPLOYMENTS_PATH = path.join(__dirname, "simplifiedDeployments");

interface TokensOutputShape {
  [tokenSymbol: string]: string;
}

async function writeOutput(erc20: MockERC20) {
  // Get symbol
  const symbol = await erc20.symbol();
  // Output
  const output: TokensOutputShape = {};
  output[symbol] = erc20.address;

  // Network name
  const networkName = hardhat.network.name;
  // File name
  const fileName = path.join(_DEPLOYMENTS_PATH, networkName, "mockTokens.json");
  // Check that file exists
  if (!fs.existsSync(fileName)) {
    const ws = fs.createWriteStream(fileName);
    ws.write(JSON.stringify(output, undefined, 2));
    ws.end();
  } else {
    // Read existing file
    const content = fs.readFileSync(fileName);
    // Stringify and parse
    const out: TokensOutputShape = JSON.parse(content.toString());
    fs.writeFileSync(fileName, JSON.stringify({ ...out, ...output }, undefined, 2));
  }
}

async function createMockTokens() {
  const mockDAI = await deploy<MockERC20>("MockERC20", "DAI Stablecoin", "DAI", parseEther("15000000000"));
  const mockBAT = await deploy<MockERC20>("MockERC20", "Basic Attention Token", "BAT", parseEther("17000000000"));
  await writeOutput(mockDAI);
  await writeOutput(mockBAT);
}

createMockTokens()
  .then(() => {
    console.log("Tokens created!");
  })
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
