require("dotenv").config();

const { z } = require("zod");

const envSchema = z
  .object({
    PRIVATE_KEY: z.string({ coerce: true }),
    TARP_PRIVATE_KEY: z.string().optional().nullable(),
    TARP_RPC_URL: z.string().optional().nullable(),
    MONAD_API_KEY: z.string().optional().nullable()
  })
  .catchall(z.any())
  .strict();

const { data, error, success } = envSchema.safeParse(process.env);

if (!success && error) {
  console.error(error);
  process.exit(1);
}

module.exports.PRIVATE_KEY = data.PRIVATE_KEY;
module.exports.MONAD_API_KEY = data.MONAD_API_KEY;
module.exports.TARP_PRIVATE_KEY = data.TARP_PRIVATE_KEY;
module.exports.TARP_RPC_URL = data.TARP_RPC_URL;
