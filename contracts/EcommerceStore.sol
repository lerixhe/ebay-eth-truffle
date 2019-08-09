pragma solidity ^0.5.10;
import "./Escrow.sol";

contract EcommerceStore {

    //定义数据结构
    struct ProductInfo{
        //产品信息相关
        uint id;   //产品id：属性自增
        string name; //产品名字
        string category; //产品类别
        string imageLink; //产品图片的ipfs哈希
        string descLink;  //差评描述信息ipfs哈希
        ProductCondition condition;//产品成色
    }
    struct ProductDetails{
        uint id;   //产品id：属性自增
        //拍卖相关
        uint startPrice;//起拍价
        uint auctionStartTime;//起拍时间
        uint auctionEndTime;//出价阶段结束时间
        ProductStatus status;//产品竞拍状态
        //竞标相关
        uint highestBid;   //最高出价
        address payable highestBidder; //最高出价人
        uint secondHighestBid; //次高价
        uint totalBids; //所有的竞标数量
        //该产品的所有竞标人
        mapping(address =>mapping(bytes32 => Bid)) bids;//把每个人的真实竞标与迷惑竞标信息单独存储
        // 注意，每次独立的竞标必须使用不同的密钥，否则会覆盖之前的竞标记录！！！
    }

    enum ProductStatus{Open,Sold,Unsold}
    enum ProductCondition{Used,New}

    // 竞标的结构
    struct Bid {
        uint productId; //产品id
        uint price; //转账价格（迷惑）
        bool isRevealed;//是否已经揭标
        address bidder;//竞标人
    }

    // 定义状态变量
    uint public productIndex;//生成产品id的计数器
    mapping(uint => address) public ProductId2Owner; //根据商品id找到对应卖家
    mapping(uint => ProductInfo) public ProductId2ProductInfo; //存储所有的商品id=>商品信息实例，并便于检索
    mapping(uint => ProductDetails) public ProductId2ProductDetails; //存储所有的商品id=>商品详情实例，并便于检索
    mapping(address => uint[]) public Owner2ProductIds; //根据卖家找到其所有商品id
    //其他全局变量
    
    
    
    constructor()public{
        productIndex = 0;
    }
    // 定义方法：
    // 1.添加商品,（msg.sender）
    function addProductToStore(string memory _name, string memory _category, string memory _imageLink, string memory _descLink, uint _startTime, uint _endTime, uint _startPrice, uint condition) public{
        productIndex++;
        ProductInfo memory productInfo = ProductInfo({
            id:productIndex,
            name:_name,
            category: _category,
            imageLink:_imageLink,
            descLink : _descLink,
            condition : ProductCondition(condition)
        });
        ProductDetails memory productDetails = ProductDetails({
            id:productIndex,
            startPrice : _startPrice,
            auctionStartTime : _startTime,
            auctionEndTime : _endTime,
            status:ProductStatus.Open,//产品竞拍状态//产品竞拍状态
            highestBid : 0,
            highestBidder: address(0),
            secondHighestBid: 0,
            totalBids: 0
        });

        // 保存到状态变量
        ProductId2Owner[productIndex] = msg.sender;
        ProductId2ProductInfo[productIndex] = productInfo;
        ProductId2ProductDetails[productIndex] = productDetails;
        Owner2ProductIds[msg.sender].push(productIndex);
    }
    //2.竞标方法
    //正常的输入值应该是，bytes32 bytesHash, 即真实价格与密文的的哈希值
    //我们这里为了方便测试，将值直接传递过来，后面在修改为哈希值
    function bid(uint _productId, uint _idealPrice, string memory _secret) public payable {
        // 获取密文
        bytes memory bytesInfo = abi.encodePacked(_idealPrice, _secret);
        bytes32 bytesHash = keccak256(bytesInfo);
        // 信息检索,产品id=>产品详情实例
        ProductDetails storage productDetails = ProductId2ProductDetails[_productId];
        //更新产品实例中的标的物信息
        productDetails.totalBids++;
        // 实例化此次投标
        Bid memory bidLocal = Bid(_productId, msg.value, false, msg.sender);
        // 存储此次投标到产品实例中
        productDetails.bids[msg.sender][bytesHash] = bidLocal;
    }
    // 辅助函数(1):返回我的某次竞标
    function getBidById(uint _productId, uint _idealPrice, string memory _secret) public view returns (uint, uint, bool, address) {
        // 通过id直接找到商品详情，从中取得所有相关竞标人与竞标信息
        // 找到我的竞标信息
        ProductDetails storage productDetails = ProductId2ProductDetails[_productId];
        //先拿到密文
        bytes memory bytesInfo = abi.encodePacked(_idealPrice, _secret);
        bytes32 bytesHash = keccak256(bytesInfo);
        // 根据密文，找到我的具体竞标信息
        Bid storage bidLocal = productDetails.bids[msg.sender][bytesHash];
        return (bidLocal.productId, bidLocal.price, bidLocal.isRevealed, bidLocal.bidder);
    }
     // 辅助函数(2):返回当前合约的余额
    function getBalance() public view returns (uint){
        return address(this).balance;
    }
    // 3.揭标方法：
    // 需要展示日志
    event revealEvent(uint8,uint, bytes32,uint,uint,uint);
    event myEvent1(address);
    // 根据商品id、真实出价、密钥来进行揭标
    function revealBid(uint _productId, uint _idealPrice, string memory _secret) public payable{
        // 先找到商品详情实例
        ProductDetails storage productDetails = ProductId2ProductDetails[_productId];
        // 根据密钥算出密文
        bytes memory bytesInfo = abi.encodePacked(_idealPrice, _secret);
        bytes32 bidId = keccak256(bytesInfo);
        
        //注意：一个人可以对同一个商品竞标多次，揭标的时候也要揭标多次, storage类型
        Bid storage currBid = productDetails.bids[msg.sender][bidId];
        emit myEvent1(currBid.bidder);
       // require(now > product.auctionStartTime);
        require(!currBid.isRevealed,"has been revealed already!");
        require(currBid.bidder != address(0),"no bidder,check if you bided or not ");  //需要找到了这个标
        //设置已揭标状态
        currBid.isRevealed = true;
        
        //揭标后，若未成为最高价，则全部退款，若成为了最高价，则以次高价成交，退回多余的部分
        // 也就是说，不断有人揭标，只要揭标人的出价比最高价低（包括时时次高价的情况），则应该立即退款
        // 若揭标人成为了最高价，则先退差价，只保留真实出价，然后将将之前的最高价全部退款。

        // 真实转账金额
        uint confusePrice = currBid.price;
        // 需退款金额
        uint refund = 0 wei;
        // 意向出价
        uint idealPrice = _idealPrice;
        uint8 statusCode = 0;
        if (confusePrice < idealPrice) {
            //路径1：无效的意向出价，退款对应数额
            refund = confusePrice;
            statusCode = 1;
        } else {
            // 与最高竞价比较，初始最高竞价为0
            if (idealPrice > productDetails.highestBid) {
                if (productDetails.highestBidder == address(0)) {
                    //当前账户是第一个揭标人
                    //路径2：
                    productDetails.secondHighestBid = productDetails.startPrice;
                    statusCode = 2;
                } else {
                    //路径3：不是第一个，但是出价是目前最高的，则将之前的最高出价，全部退回。而且最高价变成次高价
                    productDetails.highestBidder.transfer(productDetails.highestBid);
                    productDetails.secondHighestBid = productDetails.highestBid;
                    statusCode = 3;
                }
                // 更新最高竞标人，最高价格，应退差价
                productDetails.highestBid = idealPrice;
                productDetails.highestBidder = msg.sender;
                refund = confusePrice - idealPrice;
            } else {
                // 价格低于最高价
                if (idealPrice > productDetails.secondHighestBid) {
                    //路径4：如果价格高于次高价，则更新次高价
                    productDetails.secondHighestBid = idealPrice;
                    statusCode = 4;
                }
                // 只要低于最高价，就全部退款
                refund = confusePrice;
                statusCode = 5;
            }
        }
        // 输出本次揭拍日志：商品id,密文，迷惑出价，意向出价，应退金额
        emit revealEvent(statusCode,_productId,bidId,confusePrice,idealPrice, refund);
        // 最后执行退款
        if (refund > 0 wei) {
            msg.sender.transfer(refund);
        }
    }
    // 辅助函数(1):返回某商品的当前最高竞价的信息
    function getHightBidInfo(uint _productId)public view returns(address payable,uint,uint,uint){
        ProductDetails storage productDetails = ProductId2ProductDetails[_productId];

        return (productDetails.highestBidder, productDetails.highestBid, productDetails.secondHighestBid, productDetails.totalBids);
    }

    //4.终结拍卖的方法，终结后进入仲裁阶段
    mapping(uint => address) public productToEscrow;//存储产品id和仲裁合约地址的集合
    function finalaizeAuction(uint _productId) public {

        ProductDetails storage productDetails = ProductId2ProductDetails[_productId];

        address payable buyer = productDetails.highestBidder; //买家
        address payable seller = address(int160(ProductId2Owner[_productId]));//卖家
        address arbiter = msg.sender; //仲裁人

        //仲裁人不允许是买家或者卖家
        require(arbiter != buyer && arbiter != seller,'arbiter cannot be buyer or seller!');

        //限定仅在揭标之后才可以进行仲裁
        //require(now > product.auctionEndTime);

        require(productDetails.status == ProductStatus.Open,'the product status is not open!'); //Open, Sold, Unsold

        //如果竞标了，但是没有揭标，那么也是没有卖出去(自行拓展)
        if (productDetails.totalBids == 0) {
            // 无人竞标
            productDetails.status = ProductStatus.Unsold;
        } else {
            productDetails.status = ProductStatus.Sold;
        }
        // 剩下新的仲裁合约，开启投票，并将成交金额转入仲裁合约。
            //这是构造的时候传钱，constructor加上payable关键字
            //address escrow = (new Escrow).value(25)(buyer, seller, arbiter)
            // 这是fallback转钱，注意加上fallback
        Escrow escrow = new Escrow(buyer, seller, arbiter);
        address payable escrowAddr = address(int160(address(escrow)));
        escrowAddr.transfer(productDetails.secondHighestBid);
        // 存储 商品id=>仲裁合约
        productToEscrow[_productId] = escrowAddr;

        //因为以次高价成交，比用户意向价格要低，需退还差价 30- 25 = 5 ， 30是理想出价，25是次高
        buyer.transfer(productDetails.highestBid - productDetails.secondHighestBid);
    }
    // 5.获取仲裁信息方法（在主合约中）
    function getEscrowInfo(uint _productId) public view returns (address, address, address, uint, uint) {
        address payable escrowAddr = address(int160(productToEscrow[_productId]));
        return Escrow(escrowAddr).escrowInfo();
    }
    // 6.给卖家投票的方法
    function giveToSeller(uint _productId) public {
        address payable escrowAddr = address(int160(productToEscrow[_productId]));
        Escrow(escrowAddr).giveMoneyToSeller(msg.sender); //把调用人传给Escrow合约
    }
    // 7.给买家投票的方法
    function giveToBuyer(uint _productId) public {
        address payable escrowAddr = address(int160(productToEscrow[_productId]));
        Escrow(escrowAddr).giveMoneyToBuyer(msg.sender); //把调用人传给Escrow合约
    }
}