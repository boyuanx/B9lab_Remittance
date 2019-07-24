const Ownable = artifacts.require("Ownable");
const truffleAssert = require("truffle-assertions")

contract("Ownable", accounts => {
    const [owner0, owner1] = accounts;
    let ownable;

    describe("smoke tests", () => {
        beforeEach("deploy this contract as owner0", async () => {
            ownable = await Ownable.new({ from: owner0 });
        });

        it("should return the correct owner", async () => {
            const returnedOwner = await ownable.getOwner();
            assert.strictEqual(returnedOwner, owner0);
        });

        it("should change the owner from 0 to 1 and emit the correct events", async () => {
            const changeOwnerReceipt = await ownable.changeOwner(owner1, { from: owner0 });
            assert.strictEqual(changeOwnerReceipt.logs.length, 1);
            const log = changeOwnerReceipt.logs[0];
            assert.strictEqual(log.event, "LogOwnerChanged");
            assert.strictEqual(log.args.sender, owner0);
            assert.strictEqual(log.args.newOwner, owner1);
            const newOwner = await ownable.getOwner();
            assert.strictEqual(newOwner, owner1);
        });

        it("should disallow ownership change from non-owner", async () => {
            await truffleAssert.reverts(ownable.changeOwner(owner1, { from: owner1 }), "E_NO");
        });

        it ("should disallow changing owner to 0x0", async () => {
            await truffleAssert.reverts(ownable.changeOwner(web3.utils.padLeft(0, 40), { from: owner0 }), "E_IS");
        });
    })
})