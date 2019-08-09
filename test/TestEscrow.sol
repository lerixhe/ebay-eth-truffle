pragma solidity ^0.5.10;
import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Escrow.sol";

contract TestEscrow {
  Escrow esr;
  //  event myEvent(address,address,address,address);
  // 先给测试合约转钱，以供测试
  uint public initialBalance = 1 ether;

  function beforeAll() public{
    //   初始化3个用户角色
    address payable buyer = 0x4DdA9C4476bc40e77406A73858D0F4E32F7A6642;
    address payable seller = 0x50F439dfF4402c9a8d8787B1d1cD1ef19a1db6a1;
    address arbiter = 0x4e635C5571adfE2BEc4ED88554fbC9be4e88127c;

    esr = new Escrow(buyer,seller,arbiter);
    // 给被测合约转钱，当作商品最高报价。
    address(esr).transfer(1000);
    // 给买家卖家各投自己一票
    esr.giveMoneyToBuyer(buyer);
    esr.giveMoneyToSeller(seller);  }
    // 测试合约余额
    function testEscrowGetBalance() public {
        Assert.equal(esr.getBalance(),1000, "getBalance should be 1000 ");
    }
    // 测试获取投票状态
    function testEscrowInfo()public{
        uint buyerVotesCount;
        uint sellerVotesCount;
        (, , , buyerVotesCount, sellerVotesCount) = esr.escrowInfo();
        Assert.equal(buyerVotesCount,1, "buyerVotesCount should be 1 ");
        Assert.equal(sellerVotesCount,1, "buyerVotesCount should be 1 ");
    }
    // 用来接收被测试合约的转账。大坑（若干小时）
    function() external payable { }
}
