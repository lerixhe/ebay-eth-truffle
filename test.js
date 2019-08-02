// 引入合约
var EcommerceStore = artifacts.require("../contracts/EcommerceStore.sol");
var instance 
beforeAll(()=>{
    EcommerceStore.deployed().then((myinstance)=>{
        instance = myinstance
    });
});
// 类似 describe, 返回账号列表
contract('EcommerceStore', ()=>{
  it("should put 10000 MetaCoin in the first account", ()=> {
    // return EcommerceStore.deployed().then(function(instance) {
    //   return instance.productIndex.call();
    // }).then(function(id) {
    //   assert.equal(id, 0, "10000 wasn't in the first account");
    // });
    instance.productIndex.call().then((id)=>{
        assert.equal(id, 0, "10000 wasn't in the first account");
    }) 
        //   assert.equal(id, 0, "10000 wasn't in the first account");

  });
})

// const assert = require('assert');
// class Dog{
//     say(){
//         return 'wangwang';
//     }
//     happy(){
//         return 'miaomiao';
//     }
// }
// let dog
// beforeEach(()=>{
//     dog=new Dog();
// });
// describe( '测试dog',()=>{
//     it('测试dog的say方法',()=>{
//         assert.equal(dog.say(),'wangwang');
//     })
//     it('测试dog的happy方法',()=>{
//         assert.equal(dog.happy(),'miaomiao');
//     })
// });