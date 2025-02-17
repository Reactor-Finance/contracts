export interface ConstantsShape {
  teamAddress: string;
  defaultRewardTokens: string[];
  initialMintRecipients: string[];
  initialMintAmounts: bigint[];
}

export interface NetworkConstantsShape {
  [key: string]: ConstantsShape & {
    wrappedEther:
      | {
          name: string;
          symbol: string;
        }
      | string;
  };
}

export const __CONSTANTS__: NetworkConstantsShape = {
  monadTestnet: {
    teamAddress: "0xb69DB7b7B3aD64d53126DCD1f4D5fBDaea4fF578",
    defaultRewardTokens: [],
    initialMintRecipients: ["0xb69DB7b7B3aD64d53126DCD1f4D5fBDaea4fF578", "0x2749fb5F7737F3ED173aa5bA5e56BAB551AE77d7"],
    initialMintAmounts: [BigInt(7_000_000 * 1e18), BigInt(3_000_000 * 1e18)],
    wrappedEther: "0x760AfE86e5de5fa0Ee542fc7B7B713e1c5425701"
  },
  monadDevnet: {
    teamAddress: "0xb69DB7b7B3aD64d53126DCD1f4D5fBDaea4fF578",
    defaultRewardTokens: [],
    initialMintRecipients: ["0xb69DB7b7B3aD64d53126DCD1f4D5fBDaea4fF578", "0x2749fb5F7737F3ED173aa5bA5e56BAB551AE77d7"],
    initialMintAmounts: [BigInt(7_000_000 * 1e18), BigInt(3_000_000 * 1e18)],
    wrappedEther: {
      name: "Wrapped Monad",
      symbol: "WMON"
    }
  },

  tarpPrivateTestnet: {
    teamAddress: "0xb69DB7b7B3aD64d53126DCD1f4D5fBDaea4fF578",
    defaultRewardTokens: [],
    initialMintRecipients: ["0x70997970C51812dc3A010C7d01b50e0d17dc79C8", "0x90F79bf6EB2c4f870365E785982E1f101E93b906"],
    initialMintAmounts: [BigInt(7_000_000 * 1e18), BigInt(3_000_000 * 1e18)],
    wrappedEther: {
      name: "Wrapped Tarp",
      symbol: "WTARP"
    }
  },
  beraBartio: {
    teamAddress: "0xb69DB7b7B3aD64d53126DCD1f4D5fBDaea4fF578",
    defaultRewardTokens: [],
    initialMintRecipients: ["0xb69DB7b7B3aD64d53126DCD1f4D5fBDaea4fF578", "0x2749fb5F7737F3ED173aa5bA5e56BAB551AE77d7"],
    initialMintAmounts: [BigInt(7_000_000 * 1e18), BigInt(3_000_000 * 1e18)],
    wrappedEther: "0x7507c1dc16935B82698e4C63f2746A2fCf994dF8"
  },
  sepolia: {
    teamAddress: "0xb69DB7b7B3aD64d53126DCD1f4D5fBDaea4fF578",
    defaultRewardTokens: [],
    initialMintRecipients: ["0xb69DB7b7B3aD64d53126DCD1f4D5fBDaea4fF578", "0x2749fb5F7737F3ED173aa5bA5e56BAB551AE77d7"],
    initialMintAmounts: [BigInt(7_000_000 * 1e18), BigInt(3_000_000 * 1e18)],
    wrappedEther: "0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14"
  }
};
