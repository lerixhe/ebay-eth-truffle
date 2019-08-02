pragma solidity ^0.5.10;
import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/EcommerceStore.sol";

contract TestEcommerceStore {
  EcommerceStore es;
  event myEvent(address,address,address,address);
  // 先给测试合约转钱，以供测试
  uint public initialBalance = 1 ether;

  function beforeAll() public{
    // es = EcommerceStore(DeployedAddresses.EcommerceStore());
    es = new EcommerceStore();
    // 给合约添加1个商品
    es.addProductToStore("景德镇XXX","瓷器","23ed323","23e332",234232,2342343,1000,1);
    // 出价1次
    es.bid.value(500)(1,100,"lalala");
  }
  // 测试合约产品id计数器的状态
  function testEcommerceStoreproductIndex() public {
    Assert.equal(es.productIndex(),1, "productIndex should be 1 ");
  }
  // 测试根据产品id是否成功找到拍卖人
  function testEcommerceStoreProductId2Owner() public {
    emit myEvent(msg.sender,address(this),es.ProductId2Owner(1),address(es));
    // 1.测试合约的部署者，2.测试合约实例本身 3.目标合约的部署者（测试合约本身）4.最终被部署的合约本身
    Assert.equal(address(this),es.ProductId2Owner(1), "should be same ");
  }
  // 测试根据产品id，能否找到产品信息
  function testEcommerceStoreProductId2ProductInfo() public{
    string memory name;
    (,name,,,,) = es.ProductId2ProductInfo(1);
    // EcommerceStore.ProductInfo storage pro = es.ProductId2ProductInfo(1);
    Assert.equal(name,"景德镇XXX","should be same");
  }
  // 测试出价是否成功,判断是否找到出价信息
  function testEcommerceStoreGetBidById() public{
    
    uint price;
    (,price,,) = es.getBidById(1,100,"lalala");
    Assert.equal(price,500,"should be same");
  }
  // 测试合约出价之后的余额
  function testEcommerceStoreGetBalance() public{
    uint balance = es.getBalance();
    Assert.equal(balance,500,"should be same");
  }
}