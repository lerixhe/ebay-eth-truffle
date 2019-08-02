pragma solidity ^0.5.10;
import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/EcommerceStore.sol";

contract TestEcommerceStore {
  EcommerceStore es;
  event myEvent(address,address,address,address);

  // function beforeAll() public{
  //   // es = EcommerceStore(DeployedAddresses.EcommerceStore());
  //   es = new EcommerceStore();
  //   es.addProductToStore("景德镇XXX","瓷器","23ed323","23e332",234232,2342343,1000,1);

  // }
  // function testEcommerceStoreproductIndex() public {
  //   Assert.equal(es.productIndex(),1, "productIndex should be 1 ");
  // }
  function testEcommerceStoreProductId2Owner() public {
    es = new EcommerceStore();
    es.addProductToStore("景德镇XXX","瓷器","23ed323","23e332",234232,2342343,1000,1);
    emit myEvent(msg.sender,address(this),es.ProductId2Owner(1),address(es));
    Assert.equal(address(this),address(es), "should be same ");

    // 1.测试合约的部署者，2.测试合约实例本身 3.目标合约的部署者（测试合约本身）4.最终被部署的合约本身
  }
}