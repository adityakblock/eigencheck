include .env

test:
	@forge test --fork-url ${RPC_URL}
