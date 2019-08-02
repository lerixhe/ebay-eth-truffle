pragma solidity ^0.5.10;
// 为什么单独写一个合约呢？一个产品对应一个仲裁
contract Escrow{
     //全局变量：
    // 1. 买家
    address payable buyer;
    // 2. 卖家
    address payable seller;
    // 3. 仲裁人
    address arbiter;
    // 4. 卖家获得的票数
    uint sellerVotesCount;
    // 5. 买家获得的票数
    uint buyerVotesCount;
    // 6. 存储 用户=>投票与否，存储某个地址是否已经投票
    mapping(address => bool) addressVotedMap;
     // 7. 是否已经完成付款了，默认没付款。
    bool isSpent = false;
    //修饰器： 仅允许当事人执行的方法
    modifier callerRestrict(address caller ) {
        require(caller == seller || caller == buyer || caller == arbiter,"you have no permission!");
        _;
    }

    // 初始化时，从拍卖合约中取得初始数据
    constructor(address payable _buyer, address payable _seller, address _arbiter) public {
        buyer = _buyer;
        seller = _seller;
        arbiter = _arbiter;
    }
    // 辅助函数：1.取得当前合约中的余额
    function getBalance () public view returns (uint) {
        return address(this).balance;
    }
    // 辅助函数：2.取得当前合约信息
    function escrowInfo() public view returns(address, address, address, uint, uint) {
        return (buyer, seller, arbiter, buyerVotesCount, sellerVotesCount);
    }
    // 1.给买家投票的方法,用户不直接调用次方法，而是调用主合约对应方法完成，故不能用msg.sender
    function giveMoneyToBuyer(address caller)public callerRestrict(caller)  {
        require(!isSpent,"is spent already!");
        require(!addressVotedMap[caller],"you voted already!");
        addressVotedMap[caller] = true;
        // 当得票多于2票时，即认为交易达成共识，付款给买家。
        if (++buyerVotesCount == 2) {
            isSpent = true;
            buyer.transfer(address(this).balance);
        }
    }
    //给卖家投票方法
    function giveMoneyToSeller(address caller) public callerRestrict(caller)  {
        require(!isSpent,"is spent already!");
        require(!addressVotedMap[caller],"you voted already!");
        addressVotedMap[caller] = true; //address => bool
         // 当得票多于2票时，即认为交易达成共识，退款给卖家。
        if (++sellerVotesCount == 2 ) {
            isSpent = true;
            seller.transfer(address(this).balance);
        }
    }

    // fallback接受转账
    function()external payable{}
}