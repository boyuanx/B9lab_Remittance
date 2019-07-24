const Remittance = artifacts.require("Remittance");
const OTP_Gen = artifacts.require("OTP_Gen");
const truffleAssert = require("truffle-assertions");

contract("Remittance", accounts => {
    const [alice, bob, carol, dylan] = accounts;
    const { BN, toWei } = web3.utils;
    const deposit = toWei("10", "GWei");
    let otp, bobHash, carolHash, remittance;

    describe("normal cases", () => {
        before("do some initialization work", async () => {
            otp = await OTP_Gen.new({ from: alice });
            bobHash = await otp.generate(bob, "bobPW");
            bobHash1 = await otp.generate(bob, "bobPW1");
            carolHash = await otp.generate(carol, "carolPW");
            carolHash1 = await otp.generate(carol, "carolPW1");
        })

        beforeEach("do some initialization work", async () => {
            remittance = await Remittance.new(true, { from: alice });
        })

        it("should allow Alice to make a deposit and emit the correct event", async () => {
            const tx = await remittance.deposit(bob, carol, 0, bobHash, carolHash, { from: alice, value: deposit });
            truffleAssert.eventEmitted(tx, "LogDepositComplete", (ev) => {
                return (ev.sender == alice)
                && (ev.fiatRecipient == bob)
                && (ev.exchangeDst == carol)
                && (ev.amount == deposit)
                && (ev.deadline == 0);
            });
        })

        it("should not allow Alice to accidentally make multiple deposits", async () => {
            await remittance.deposit(bob, carol, 0, bobHash, carolHash, { from: alice, value: deposit });
            truffleAssert.reverts(remittance.deposit(bob, carol, 0, bobHash, carolHash, { from: alice, value: deposit }), "E_TAE");
        })

        it("should not allow Alice to make a deposit with an expired deadline", async () => {
            const currentBlockNumber = await web3.eth.getBlockNumber();
            truffleAssert.reverts(remittance.deposit(bob, carol, currentBlockNumber, bobHash, carolHash, { from: alice, value: deposit }), "E_DE");
        })

        it("should let bob & carol withdraw correctly and emit the correct events", async () => {
            const carolBalance = await web3.eth.getBalance(carol);
            await remittance.deposit(bob, carol, 0, bobHash, carolHash, { from: alice, value: deposit });
            const bobTx = await remittance.withdraw(carol, bobHash, { from: bob });
            const carolTx = await remittance.withdraw(carol, carolHash, { from: carol });
            const gasUsed = carolTx.receipt.gasUsed;
            const gasPrice = (await web3.eth.getTransaction(carolTx.tx)).gasPrice;
            const carolNewBalance = await web3.eth.getBalance(carol);
            truffleAssert.eventEmitted(bobTx, "LogWithdrawPending", (ev) => {
                return (ev.fiatRecipient == bob)
                && (ev.exchangeDst == carol)
                && (ev.amount == deposit);
            })
            truffleAssert.eventEmitted(carolTx, "LogWithdrawComplete", (ev) => {
                return (ev.fiatRecipient == bob)
                && (ev.exchangeDst == carol)
                && (ev.amount == deposit);
            })
            assert.strictEqual(carolNewBalance, (new BN(carolBalance)).add(new BN(deposit)).sub(new BN(gasPrice*gasUsed)).toString(10));
        })

        it("shouldn't let Alice reclaim active deposits", async () => {
            await remittance.deposit(bob, carol, 0, bobHash, carolHash, { from: alice, value: deposit });
            truffleAssert.reverts(remittance.reclaim(carol, bobHash, carolHash, { from: alice }), "E_TNE");
        })

        it("shouldn't allow people accessing other people's deposits even with their password stolen", async () => {
            await remittance.deposit(bob, carol, 0, bobHash, carolHash, { from: alice, value: deposit });
            truffleAssert.reverts(remittance.withdraw(carol, bobHash, { from: dylan }), "E_TNF");
            await remittance.withdraw(carol, bobHash, { from: bob });
            await remittance.withdraw(carol, carolHash, { from: carol });
        })
    })
})