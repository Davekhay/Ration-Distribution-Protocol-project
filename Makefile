# === Load environment variables from .env ===
# Requires PRIVATE_KEY and SEPOLIA_RPC_URL in your .env file

# === Make Commands ===

# Run all tests with verbose output
test:
	forge test -vvv

# Run tests with gas report
gas:
	forge test --gas-report -vvv

# Format all contracts
fmt:
	forge fmt

# Clean build artifacts
clean:
	forge clean

# Deploy to Sepolia testnet
deploy-sepolia:
	forge script script/Deploy.s.sol:DeployScript --rpc-url $$SEPOLIA_RPC_URL --broadcast --private-key $$PRIVATE_KEY -vvvv

# Simulate deployment using Sepolia fork
dry-run:
	forge script script/Deploy.s.sol:DeployScript --fork-url $$SEPOLIA_RPC_URL -vvvv

# Verify contract on Sepolia Etherscan (optional)
verify:
	forge verify-contract --chain-id 11155111 --num-of-optimizations 200 \
	    --watch --etherscan-api-key $$ETHERSCAN_API_KEY \
	    <DEPLOYED_CONTRACT_ADDRESS> src/RationDistribution.sol:RationDistribution

