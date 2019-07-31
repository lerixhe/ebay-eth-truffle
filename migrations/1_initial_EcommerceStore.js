const Migrations = artifacts.require('./EcommerceStore.sol');

module.exports = function(deployer) {
  deployer.deploy(Migrations);
};
