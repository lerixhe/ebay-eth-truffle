pragma solidity ^0.5.10;

contract EcommerceStore {

    //定义数据结构
    struct Product{
        uint id;   //产品id：属性自增
        string name; //产品名字
        string category; //产品类别
        string imageLink; //产品图片的ipfs哈希
        string descLink;  //差评描述信息ipfs哈希


        uint startPrice;//起拍价
        uint auctionStartTime;//起拍时间
        uint auctionEndTime;//出价阶段结束时间

        ProductStatus status;//产品竞拍状态
        ProductCondition condition;//产品成色
    }
    enum ProductStatus{Open,Sold,Unsold}
    enum ProductCondition{Used,New}

    // 定义状态变量
    uint public productIndex;//生成产品id的计数器
    mapping(uint => address) public ProductId2Owner; //根据商品id找到对应卖家
    // mapping(uint => Product) public ProductId2Prodect; //根据商品id找到商品实例,冗余，两个就够了
    mapping(address => mapping(uint => Product)) public Owner2Prodect; //根据卖家找到其所有商品

    constructor()public{
        productIndex = 0;
    }
    // 定义方法：
    // 1.添加商品,（msg.sender）
    function addProductToStore(string memory _name, string memory _category, string memory _imageLink, string memory _descLink, uint _startTime, uint _endTime, uint _startPrice, uint condition) public{
        productIndex++;
        Product memory product = Product({
            id:productIndex,
            name:_name,
            category: _category,
            imageLink:_imageLink,
            descLink : _descLink,

            startPrice : _startPrice,
            auctionStartTime : _startTime,
            auctionEndTime : _endTime,
 
            status : ProductStatus.Open,
            condition : ProductCondition(condition)
        });

        // 保存到状态变量
        ProductId2Owner[productIndex] = msg.sender;
        Owner2Prodect[msg.sender][productIndex] = product;
    }
}