const Remittance = artifacts.require("Remittance");
const OTP = artifacts.require("OTP");
const truffleAssert = require("truffle-assertions");

contract("Remittance", async (accounts) => {
    const [alice, carol, dylan] = accounts;
    const { BN, toWei } = web3.utils;
    const deposit = toWei("10", "GWei");
    const _otp = await OTP.deployed();
    await Remittance.link("OTP", _otp.address);
    const bobSeed = await _otp.stringToBytes32Hash("bobPW", { from: carol });
    let depositHash, remittance;

    describe("normal cases", () => {
        beforeEach("do some initialization work", async () => {
            remittance = await Remittance.new(true, 35040, { from: alice });
            depositHash = await _otp.generate(remittance.address, carol, bobSeed, { from: alice });
        })

        it("should allow Alice to make a deposit and emit the correct event with a modified default deadline", async () => {
            await remittance.setDefaultDeadlineDelay(10, { from: alice });
            const tx = await remittance.deposit(0, depositHash, { from: alice, value: deposit });
            truffleAssert.eventEmitted(tx, "LogDeposited", (ev) => {
                return (ev.sender == alice)
                && (ev.amount == deposit)
                && (ev.deadline == tx.receipt.blockNumber + 10)
                && (ev.hash == depositHash);
            });
        })

        it("should not allow Alice to accidentally make multiple deposits", async () => {
            await remittance.deposit(0, depositHash, { from: alice, value: deposit });
            truffleAssert.reverts(remittance.deposit(0, depositHash, { from: alice, value: deposit }), "E_TAE");
        })

        it("should not allow Alice to make a deposit with an expired deadline", async () => {
            const currentBlockNumber = await web3.eth.getBlockNumber();
            truffleAssert.reverts(remittance.deposit(currentBlockNumber, depositHash, { from: alice, value: deposit }), "E_DE");
        })

        it("should let bob & carol withdraw correctly and emit the correct events", async () => {
            const carolBalance = await web3.eth.getBalance(carol);
            await remittance.deposit(0, depositHash, { from: alice, value: deposit });
            const tx = await remittance.withdraw(bobSeed, { from: carol });
            const gasUsed = tx.receipt.gasUsed;
            const gasPrice = (await web3.eth.getTransaction(tx.tx)).gasPrice;
            const carolNewBalance = await web3.eth.getBalance(carol);
            truffleAssert.eventEmitted(tx, "LogWithdrew", (ev) => {
                return (ev.sender == alice)
                && (ev.amount == deposit)
                && (ev.hash == depositHash);
            })
            assert.strictEqual(carolNewBalance, (new BN(carolBalance)).add(new BN(deposit)).sub(new BN(gasPrice*gasUsed)).toString(10));
        })

        it("shouldn't let Alice reclaim active deposits", async () => {
            await remittance.deposit(0, depositHash, { from: alice, value: deposit });
            truffleAssert.reverts(remittance.reclaim(depositHash, { from: alice }), "E_TNE");
        })

        it("should let Alice reclaim expired deposits", async () => {
            const futureBlockNumber = await web3.eth.getBlockNumber() + 2;
            await remittance.deposit(futureBlockNumber, depositHash, { from: alice, value: deposit });
            web3.currentProvider.send({
                jsonrpc: "2.0",
                method: "evm_mine",
                id: 5777
            }, function(err) { if (err) { console.log(err); }});
            remittance.reclaim(depositHash, { from: alice });
        })

        it("shouldn't allow people accessing other people's deposits even with their password stolen", async () => {
            await remittance.deposit(0, depositHash, { from: alice, value: deposit });
            truffleAssert.reverts(remittance.withdraw(bobSeed, { from: dylan }), "E_EF");
            await remittance.withdraw(bobSeed, { from: carol });
        })

        it("shouldn't let people deposit when deposit is closed but shouldn't affect withdraw", async () => {
            await remittance.deposit(0, depositHash, { from: alice, value: deposit });
            await remittance.pauseContract({ from: alice });
            await remittance.killContract({ from: alice });
            truffleAssert.reverts(remittance.deposit(0, depositHash, { from: alice, value: deposit }), "E_NR");
            await remittance.withdraw(bobSeed, { from: carol });
        })
    })
})