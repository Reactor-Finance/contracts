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
