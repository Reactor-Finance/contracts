require("dotenv").config();

const { z } = require("zod");

const envSchema = z
  .object({
    PRIVATE_KEY: z.string({ coerce: true }),
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
