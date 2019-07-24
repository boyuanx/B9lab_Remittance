const Stoppable = artifacts.require("Stoppable");
const truffleAssert = require("truffle-assertions")

contract("Stoppable", accounts => {
    const owner = accounts[0];
    let stoppable;

    describe("deploying as running", () => {
        beforeEach("deploy this contract as running", async () => {
            stoppable = await Stoppable.new(true, { from: owner });
        })

        it("should be running", async () => {
            assert.strictEqual(true, await stoppable.isRunning());
        })

        it("should be able to be paused", async () => {
            const pauseReceipt = await stoppable.pauseContract({ from: owner });
            assert.strictEqual(false, await stoppable.isRunning());
            assert.strictEqual(pauseReceipt.logs.length, 1);
            const log = pauseReceipt.logs[0];
            assert.strictEqual(log.event, "LogPausedContract");
            assert.strictEqual(log.args.sender, owner);
        })

        it("should not be able to be resumed", async () => {
            await truffleAssert.reverts(stoppable.resumeContract({ from: owner }), "E_NP");
        })

        it("should not be able to be killed", async () => {
            truffleAssert.reverts(stoppable.killContract({ from: owner }), "E_NP")
        })
    })

    describe("deploying as paused", () => {
        beforeEach("deploy this contract as paused", async () => {
            stoppable = await Stoppable.new(false, { from: owner });
        })

        it("should be paused", async () => {
            assert.strictEqual(false, await stoppable.isRunning());
        })

        it("should be able to be resumed", async () => {
            const resumedReceipt = await stoppable.resumeContract({ from: owner });
            assert.strictEqual(true, await stoppable.isRunning());
            assert.strictEqual(resumedReceipt.logs.length, 1);
            const log = resumedReceipt.logs[0];
            assert.strictEqual(log.event, "LogResumedContract");
            assert.strictEqual(log.args.sender, owner);
        })

        it("should not be able to be paused", async () => {
            await truffleAssert.reverts(stoppable.pauseContract({ from: owner }), "E_NR");
        })

        it("should be killed and cannot be revived", async () => {
            const killReceipt = await stoppable.killContract({ from: owner });
            assert.strictEqual(false, await stoppable.isAlive());
            truffleAssert.eventEmitted(killReceipt, "LogKilledContract", { sender: owner });
            await truffleAssert.reverts(stoppable.resumeContract({ from: owner }), "E_NP");
            await truffleAssert.reverts(stoppable.pauseContract({ from: owner }), "E_NR");
        })
    })
})