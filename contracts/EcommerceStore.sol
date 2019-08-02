pragma solidity ^0.5.10;

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
        address highestBidder; //最高出价人
        uint secondHighestBid; //次高价
        uint totalBids; //所有的竞标数量
        //该产品的所有竞标人
        mapping(address =>mapping(bytes32 => Bid)) bids;//把每个人的真实竞标与迷惑竞标信息单独存储
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
        ProductDetails storage product = ProductId2ProductDetails[_productId];
        //先拿到密文
        bytes memory bytesInfo = abi.encodePacked(_idealPrice, _secret);
        bytes32 bytesHash = keccak256(bytesInfo);
        // 根据密文，找到我的具体竞标信息
        Bid memory bidLocal = product.bids[msg.sender][bytesHash];
        return (bidLocal.productId, bidLocal.price, bidLocal.isRevealed, bidLocal.bidder);
    }
}