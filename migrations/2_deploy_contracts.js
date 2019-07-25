const Remittance = artifacts.require('Remittance.sol');
const OTP = artifacts.require('OTP.sol');

module.exports = async function (deployer) {
    await deployer.deploy(OTP, true);
    await deployer.link(OTP, Remittance);
    await deployer.deploy(Remittance, true);

    // deployer.deploy(Remittance, true).then(() => {
    //     deployer.deploy(OTP, true);
    // });
    // deployer.link(Remittance, OTP);
};