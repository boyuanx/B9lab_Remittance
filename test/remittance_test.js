const Remittance = artifacts.require("Remittance");
const OTP = artifacts.require("OTP");
const truffleAssert = require("truffle-assertions");

contract("Remittance", accounts => {
    const [alice, carol, dylan] = accounts;
    const { BN, toWei } = web3.utils;
    const deposit = toWei("10", "GWei");
    let _otp, bobSeed, carolSeed, depositHash, remittance;

    describe("normal cases", () => {
        before("do some initialization work", async () => {
            _otp = await OTP.new({ from: alice });
            bobSeed = "bobPW";
            carolSeed = "carolPW";
            depositHash = await _otp.generate(carol, bobSeed, carolSeed, { from: alice });
        })

        beforeEach("do some initialization work", async () => {
            remittance = await Remittance.new(true, { from: alice });
        })

        it("should allow Alice to make a deposit and emit the correct event", async () => {
            const tx = await remittance.deposit(carol, 0, depositHash, { from: alice, value: deposit });
            truffleAssert.eventEmitted(tx, "LogDeposited", (ev) => {
                return (ev.sender == alice)
                && (ev.dst == carol)
                && (ev.amount == deposit)
                && (ev.deadline == 0);
            });
        })

        it("should not allow Alice to accidentally make multiple deposits", async () => {
            await remittance.deposit(carol, 0, depositHash, { from: alice, value: deposit });
            truffleAssert.reverts(remittance.deposit(carol, 0, depositHash, { from: alice, value: deposit }), "E_TAE");
        })

        it("should not allow Alice to make a deposit with an expired deadline", async () => {
            const currentBlockNumber = await web3.eth.getBlockNumber();
            truffleAssert.reverts(remittance.deposit(carol, currentBlockNumber, depositHash, { from: alice, value: deposit }), "E_DE");
        })

        it("should let bob & carol withdraw correctly and emit the correct events", async () => {
            const carolBalance = await web3.eth.getBalance(carol);
            await remittance.deposit(carol, 0, depositHash, { from: alice, value: deposit });
            const tx = await remittance.withdraw(bobSeed, carolSeed, { from: carol });
            const gasUsed = tx.receipt.gasUsed;
            const gasPrice = (await web3.eth.getTransaction(tx.tx)).gasPrice;
            const carolNewBalance = await web3.eth.getBalance(carol);
            truffleAssert.eventEmitted(tx, "LogWithdrew", (ev) => {
                return (ev.sender == alice)
                && (ev.dst == carol)
                && (ev.amount == deposit);
            })
            assert.strictEqual(carolNewBalance, (new BN(carolBalance)).add(new BN(deposit)).sub(new BN(gasPrice*gasUsed)).toString(10));
        })

        it("shouldn't let Alice reclaim active deposits", async () => {
            await remittance.deposit(carol, 0, depositHash, { from: alice, value: deposit });
            truffleAssert.reverts(remittance.reclaim(depositHash, { from: alice }), "E_TNE");
        })

        it("shouldn't allow people accessing other people's deposits even with their password stolen", async () => {
            await remittance.deposit(carol, 0, depositHash, { from: alice, value: deposit });
            truffleAssert.reverts(remittance.withdraw(bobSeed, carolSeed, { from: dylan }), "E_UA");
            await remittance.withdraw(bobSeed, carolSeed, { from: carol });
        })
    })
})