const { ethers } = require('hardhat')
const { expect } = require('chai').use(require('chai-as-promised'))

describe("Staking", () => {

    let deployer, staking, rewardsToken, collection1, collection2

    beforeEach(async () => {

        [deployer] = await ethers.getSigners()

        const RewardsToken = await ethers.getContractFactory('RewardsToken')
        rewardsToken = await RewardsToken.deploy()
        await rewardsToken.deployed()

        const Staking = await ethers.getContractFactory('Staking')
        staking = await Staking.deploy(rewardsToken.address)
        await staking.deployed()

        await rewardsToken.addController(staking.address)

        const NFTCollection = await ethers.getContractFactory('NFTCollection')

        collection1 = await NFTCollection.deploy()
        collection2 = await NFTCollection.deploy()

        await Promise.all([
            collection1.deployed(),
            collection2.deployed(),
        ])

        
        let promises = []
        for (let i = 0; i < 5; i++) {
            promises.push(collection1.mint)
            promises.push(collection2.mint)
        }

        await Promise.all(promises.map(p => p()))

        await collection1.setApprovalForAll(staking.address, true)
        await collection2.setApprovalForAll(staking.address, true)

    })

    it('should stake and unstake nft from different collections', async () => {

        await staking.stake(collection1.address,[1,2,3,4,5]);
        await staking.stake(collection2.address,[1,2,3,4,5]);

        let totalStakes = await staking.totalStakes()
    
        expect(totalStakes.toString()).to.eq("10")

        await staking.unstake(collection1.address,[1,2],[false,false]);
        await staking.unstake(collection2.address,[1,2,3],[false,false,false]);

        totalStakes = await staking.totalStakes()
    
        expect(totalStakes.toString()).to.eq("5")

    })
    it('should claim the reward', async () => {

        let earned =await rewardsToken.balanceOf(deployer.address)
        
        expect(earned).to.eq(0)

        await staking.stake(collection1.address,[1,2,3,4,5]);
        await staking.stake(collection2.address,[1,2,3,4,5]);
        
        await staking.claim(collection1.address,[1,2,3,4,5]);
        await staking.claim(collection2.address,[1,2,3,4,5]);
    
        earned =await rewardsToken.balanceOf(deployer.address)
        
        console.log(ethers.utils.formatEther(earned))
        
        expect(earned).to.gt(0)

    })
    
    it('should emit liquidation event', async () => {
        await staking.stake(collection1.address,[1,2]);

        const tx = await staking.unstake(collection1.address,[1,2],[true,true]);
        const receipt = await tx.wait()

        expect(receipt.events.filter(e=>e.event==="Liquidated").length).to.eq(2)

    })
})