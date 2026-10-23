
## Forge deployment scripts

Import the EVM wallet with `cast wallet import <name> --interactive`. Run scripts
with `forge script <script> --account <name> --sender <public-address>` and the
existing RPC and simulation options. Add `--broadcast` only when intending to send.
Scripts use the Foundry broadcaster rather than reading a private key from env.
When a script needs a deployer address in its constructor or setup, configure
`DEPLOYER_ADDRESS` to the same public address. For automation, use a separately
mounted password file via `ETH_PASSWORD` or `--password-file`, never a password value
in argv or env. Remove all legacy private key entries from local and CI environments.
