var ICOContract = artifacts.require("./ICOContract.sol");
var InvestContract = artifacts.require("./InvestContract.sol");
var Token = artifacts.require("./Token.sol");
//var Migrations = artifacts.require("./Migrations.sol");
var artifactor = require("truffle-artifactor");


//TOKEN PARAMETERS
var testdecimals = 9;
var testname = "testname";
var testsymbol = "testsymbol";

//ICOContract parameters
var sealTimestamp = 1517655288;
var minimumCap = 10000000000000000000;
var maximumCap = 10*minimumCap;

//InvestContract parameters
var investEther = 1000000000000000000;
var investToken = 20;


module.exports = async function(deployer, network, accounts) {
    //await deployer.deploy(Migrations);
    var projectWallet = accounts[3]
    var investor = accounts[4];
    if (network == 'test') {
        //token = await deployer.deploy(Token, testname, testsymbol, testdecimals);
        //token = await Token.deployed();
        //await deployer.deploy(ICOContract, token.address, projectWallet, sealTimestamp, minimumCap, maximumCap);
        //icoContract = await ICOContract.deployed();

        //await token.mint(icoContract.address, 12345)

        /*
        console.log("Running migrations for testing");

        //token deploy
        token = await Token.new(testname, testsymbol, testdecimals, {from: accounts[0]});

        //ICOContract deploy
        icoContract = await ICOContract.new(token.address, projectWallet, sealTimestamp, minimumCap, maximumCap);
        console.log('icoContract address is: ', icoContract.address)
        tokenBalance = await token.balanceOf.call(icoContract.address);
        console.log('icoContract token balance is: ', tokenBalance.valueOf());

        //Adding milestone
		var etherAmount = 10;
		var tokenAmount = 1000;
		var startTime = 1516620617;
		var finishTime = startTime + 3600*168;
		var description = "test milestone";
		var result = "test result";
		await icoContract.addMilestone(etherAmount, tokenAmount, startTime, finishTime, description, result);
		var a = await icoContract.milestonesLength.call({from: accounts[0]});
		console.log('milestones length: ', a.valueOf());

        original = await icoContract.totalEther.call();
        await icoContract.editMilestone(0, 15, tokenAmount, startTime, finishTime, "edited description", result, 1)

        milestone = await icoContract.milestones.call(0)
        console.log('milestoneInfo: ', milestone[0].valueOf())

        //InvestContract addition
        await icoContract.createInvestContract(investor, investEther, investToken);
        var b = await icoContract.getPendingLength.call();
        console.log('pending contracts length: ', b.valueOf());
        //investContract = icoContract.pendingInvestContracts[1];
        //await web3.eth.sendTransaction({from: investor, value: investEther, to: investContract, gas: 6500000});
        */

    } else {
        //deployer.deploy(ICOContract, "");
        // First deploys token, then depoloys ICOContract with Token address and other parameters
        //deployer.deploy(Token, "test", "ttt", 3).then(function() {
            //return deployer.deploy(ICOContract, Token.address, "0xc9584E27Adf724121C24fc887b4E79B6aEca6cA4", "0x4C67EB86d70354731f11981aeE91d969e3823c39", 123456, 10000, 1000000);
        //});
    }
};
