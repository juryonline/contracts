//Soon to be ported from private repository

var Token = artifacts.require('Token')
//var Token = artifacts.require('TokenWithoutStart')
var ICOContract = artifacts.require('ICOContract')
var InvestContract = artifacts.require('InvestContract')

const mineOneBlock = async () => {
    await web3.currentProvider.send({
        jsonrpc: "2.0",
        method: "evm_mine",
        params: [],
        id: 0
    });
};



contract('Token', function(accounts) {
    testdecimals = 9;
    testname = "testname";
    testsymbol = "testsymbol";
    it('Deploy of the token contract', async function() {
        token = await Token.new(testname, testsymbol, testdecimals, {from: accounts[0]});
        name = await token.name.call();
        symbol = await token.symbol.call();
        decimals = await token.decimals.call();
        assert.equal(name, testname, 'name value of deployed token is incorrect');
        assert.equal(symbol, testsymbol, 'symbol value of deployed token is incorrect');
        assert.equal(decimals, testdecimals, 'decimals value of deployed token is incorrect');
    });
    it('Minting of tokens', async function() {
        mint_amount = "12345";
        await token.mint(accounts[0], mint_amount, {from: accounts[0]});
        total = await token.totalSupply();
        balance = await token.balanceOf.call(accounts[0]);
        assert.equal(total.valueOf(), mint_amount, 'totalSupply is incorrect after minting');
        assert.equal(balance.valueOf(), mint_amount, 'balance is incorrect after minting');
    });

});

contract('ICOContract', function(accounts) {


    var investor = accounts[2];
    //ICOContract deploy parameters:
    var projectWallet = accounts[3];
	var sealTimestamp = 2000000000;
    var startTime =     1516620617;
	var minimumCap = 100;
	var maximumCap = 10*minimumCap;

    //milestone parameters
    var etherAmount = 10000000000;
    var tokenAmount = 100000;
    //var startTime = 1516620617;
    var duration = 3600;
    var finishTime = 0;
    var description = "test milestone";
    var result = "test result";
    testdecimals = 9;
    testname = "testname";
    testsymbol = "testsymbol";

    async function prepare() { //one day I will use this function
        icoContract = await ICOContract.new(token.address, projectWallet, sealTimestamp, minimumCap, maximumCap, accounts[0], {from: accounts[0]});
        token = await Token.new(testname, testsymbol, testdecimals, {from: accounts[0]});
        await token.mint(icoContract.address, tokenAmount*100, {from: accounts[0]});
        await token.start({from: accounts[0]});
        await icoContract.addMilestone(etherAmount, tokenAmount, startTime, duration, description, "", {from: accounts[0]});
        await icoContract.addMilestone(etherAmount*2, tokenAmount*2, startTime, duration, description, "doubled", {from: accounts[0]});
        await icoContract.addMilestone(etherAmount*5, tokenAmount*5, startTime, duration, description, "x5", {from: accounts[0]});
        await icoContract.seal({from: accounts[0]});
    };

    it('Deploy of Token contract', async function() {
        token = await Token.new(testname, testsymbol, testdecimals, {from: accounts[0]});
    });
    it('Deploy of ICOContract', async function() {
        icoContract = await ICOContract.new(token.address, projectWallet, sealTimestamp, minimumCap, maximumCap, accounts[0], {from: accounts[0]});
    });
    it('Minting tokens to ICOContract', async function() {
        await token.mint(icoContract.address, tokenAmount*100, {from: accounts[0]});
        await token.start({from: accounts[0]});
        balance = await token.balanceOf(icoContract.address);
        assert.equal(balance.valueOf(), tokenAmount*100, "Tokens have not been minted to the ICOContract");
    });
    it('Adding milestones', async function() {
        await icoContract.addMilestone(etherAmount, tokenAmount, startTime, duration, description, "", {from: accounts[0]});
        await icoContract.addMilestone(etherAmount*5, tokenAmount*2, startTime, duration, description, "second milestone", {from: accounts[0]});
        await icoContract.addMilestone(etherAmount*2, tokenAmount*5, startTime, duration, description, "first milestone", {from: accounts[0]});
        len = await icoContract.milestonesLength.call();
        assert.equal(len.valueOf(), 3, "Milestones have not been added");
    });
    it('Sealing ICOContract', async function() {
        tstampBeforeSeal = await icoContract.sealTimestamp();
        assert.equal(tstampBeforeSeal.valueOf(), sealTimestamp, 'Initial sealTimestamp is not correct');

        await icoContract.seal({from: accounts[0]});

        tstampAfterSeal = await icoContract.sealTimestamp();
        assert.notEqual(tstampAfterSeal.valueOf(), sealTimestamp, 'Seal timestamp has not been updated');
        await mineOneBlock();
    });
    it('Create an InvestContract.', async function(){
        investContractAddress = await icoContract.createInvestContract.call(investor, etherAmount, tokenAmount);
        await icoContract.createInvestContract(investor, etherAmount, tokenAmount, {from: accounts[0]});
        investContract = InvestContract.at(investContractAddress);
    });
    it('Adding arbiters', async function() {
        await investContract.addAcceptedArbiter(accounts[5], {from: investor});
        await investContract.addAcceptedArbiter(accounts[6], {from: investor});
        await investContract.addAcceptedArbiter(accounts[7], {from: investor});
        await investContract.addAcceptedArbiter(accounts[8], {from: investor});
        await investContract.addAcceptedArbiter(accounts[9], {from: investor});
        arbiterAcceptCount = await investContract.arbiterAcceptCount();
        assert.equal(arbiterAcceptCount, 5, 'Arbiters have not been added');
    });
    it('Send money to InvestContract', async function() {
        amountToPay = await investContract.amountToPay();
        await web3.eth.sendTransaction({from: investor, value: amountToPay.valueOf(), to: investContractAddress, gas: 5000000});

        p0 = Math.floor(etherAmount/8);
        p1 = Math.floor(5*etherAmount/8);
        p2 = Math.floor(2*etherAmount/8);
        p0 = etherAmount-(p1+p2) 
        
        part0 = await investContract.etherPartition(0);
        part1 = await investContract.etherPartition(1);
        part2 = await investContract.etherPartition(2);

        try {
            part3 = await investContract.etherPartition(3);
        } catch (e) {
            true
            //assert.equal(part3, 0, 'InvestContract has incorrect milestone Ether partition length');
        }

        assert.equal(part0.valueOf(), p0, 'InvestContract has incorrect first milestone Ether partition');
        assert.equal(part1.valueOf(), p1, 'InvestContract has incorrect second milestone Ether partition');
        assert.equal(part2.valueOf(), p2, 'InvestContract has incorrect third milestone Ether partition');
    });
    it('Create second InvestContract.', async function(){
        investContractAddress2 = await icoContract.createInvestContract.call(investor, etherAmount, tokenAmount);
        await icoContract.createInvestContract(investor, etherAmount*10, tokenAmount, {from: accounts[0]});
        investContract2 = InvestContract.at(investContractAddress2);
    });
    it('Send money to InvestContract2', async function() {
        amountToPay = await investContract2.amountToPay();
        try {
            await web3.eth.sendTransaction({from: investor, value: amountToPay.valueOf(), to: investContractAddress2, gas: 4000000});
        } catch(e) {
            true
        }
        assert.notEqual(web3.eth.getBalance(investContractAddress2).toNumber(), Math.floor(etherAmount*10*1.01), '2nd invest contract has not received correct amount of Ether');
    });

    it('Starting milestone', async function() {
        await icoContract.startNextMilestone({from: accounts[0]});
        await icoContract.finishMilestone("qwe", {from: accounts[0]});
    });
    it('Withdrawing via from async send', async function() {
        bal = await token.balanceOf(investor);
        assert.equal(bal.valueOf(), 0, 'Investor token balance is incorrect before withdrawal');

        bal2 = await investContract.tokenPayments(investor);
        tpart0 = await investContract.tokenPartition(0);
        tpart1 = await investContract.tokenPartition(1);
        assert.equal(bal2.valueOf(), tpart0.valueOf(), 'InvestContract withdrawToken amount is incorrect');

        await icoContract.startNextMilestone({from: accounts[0]});

        await investContract.withdrawTokenPayment({from: investor});
        tokenBalance = await token.balanceOf(investor);
        assert.equal(tokenBalance.valueOf(), tpart0.toNumber()+tpart1.toNumber(), 'Investor token balance is incorrect before after milestone started')

        toWithdraw = await investContract.payments(projectWallet);
        assert.equal(toWithdraw.toNumber(), part0.toNumber()+part1.toNumber());

        //balanceBeforeSend = web3.eth.getBalance(projectWallet);
        //gas = await investContract.withdrawPayment.estimateGas({from: projectWallet});
        //await investContract.withdrawPayment({from: projectWallet});
        //balanceAfterSend = web3.eth.getBalance(projectWallet);
        //assert.equal(balanceAfterSend.toNumber(), balanceBeforeSend.toNumber()+gas+part0.toNumber()+part1.toNumber(), "Project wallet hasn't withdrawn correct amount of Ether");
    });
    it('Opening a dispute', async function() {
        await investContract.openDispute("dispute", {from: investor});
        disputing = await investContract.disputing();
        assert.equal(disputing, true, 'Dispute has not opened');
    });
    it('Voting', async function() {
        toWithdraw = await investContract.payments(investor);
        //console.log(toWithdraw.toNumber())

        //assert.equal(toWithdraw.toNumber(), part0.toNumber()+part1.toNumber());
        index = await icoContract.investContractsIndices.call(investContract.address);
        console.log(index.valueOf())

        await investContract.vote(investor, {from: accounts[5]});
        await investContract.vote(investor, {from: accounts[6]});
        await investContract.vote(investor, {from: accounts[7]});

        disputing = await investContract.disputing();
        //assert.equal(disputing, false, 'Dispute has not been resolved');

        index = await icoContract.investContractsIndices.call(investContract.address);
        console.log(index.valueOf())

        toWithdraw = await investContract.payments(investor);
        //console.log(toWithdraw.toNumber())
        //toWithdraw = await investContract.payments(projectWallet);
        //assert.equal(toWithdraw.toNumber(), part0.toNumber()+part1.toNumber());
    });

});
