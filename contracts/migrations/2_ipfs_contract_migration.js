const IPFSContract = artifacts.require("IPFS")

module.exports = function (deployer) {
	deployer.deploy(IPFSContract)
}
