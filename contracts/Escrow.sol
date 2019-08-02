pragma solidity ^0.5.10;
// 为什么单独写一个合约呢？一个产品对应一个仲裁
contract Escrow{
     //全局变量：
    // 1. 买家
    address buyer;
    // 2. 卖家
    address seller;
    // 3. 仲裁人
    address arbiter;
    // 4. 卖家获得的票数
    uint sellerVotesCount;
    // 5. 买家获得的票数
    uint buyerVotesCount;
    // 初始化时，从拍卖合约中取得初始数据
    constructor(address _buyer, address _seller, address _arbiter) public payable {
        buyer = _buyer;
        seller = _seller;
        arbiter = _arbiter;
    }
    // 取得当前合约中的余额
    function getBalance () public view returns (uint) {
        return address(this).balance;
    }
    // 取得当前合约信息
    function escrowInfo() public view returns(address, address, address, uint, uint) {
        return (buyer, seller, arbiter, buyerVotesCount, sellerVotesCount);
    }
    function()external payable{}
}