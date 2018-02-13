//Soon to be ported from private repository

var Token = artifacts.require('Token')
var ICOContract = artifacts.require('ICOContract')
var InvestContract = artifacts.require('InvestContract')

contract('Token', function(accounts) {
    testdecimals = 9;
    testname = "testname";
    testsymbol = "testsymbol";
    it('Deploy of the token contract', async function() {
        token = await Token.new(testname, testsymbol, testdecimals, {from: accounts[0]});
        //console.log("token address: ", tok.address);
        //console.log("owner address: ", accounts[0]);
        name = await token.name.call();
        symbol = await token.symbol.call();
        decimals = await token.decimals.call();
        assert.equal(name, testname, 'name value of deployed token is incorrect');
        assert.equal(symbol, testsymbol, 'symbol value of deployed token is incorrect');
        assert.equal(decimals, testdecimals, 'decimals value of deployed token is incorrect');
    });
    it('Minting of tokens', async function() {
        mint_amount = "12345";
        await token.mint(accounts[0],mint_amount, {from: accounts[0]});
        total = await token.totalSupply();
        balance = await token.balanceOf.call(accounts[0]);
        assert.equal(total.valueOf(), mint_amount, 'totalSupply is incorrect after minting');
        assert.equal(balance.valueOf(), mint_amount, 'balance is incorrect after minting');
    });
});

contract('ICOContract', function(accounts) {
    var investor = accounts[2];
    var arbiter1 = accounts[5];
    var arbiter2 = accounts[6];
    var arbiter3 = accounts[7];
    //ICOContract deploy parameters:
    var projectWallet = accounts[3];
	var sealTimestamp = 2000000000
	var minimumCap = 1000000000000000000;
	var maximumCap = 10*minimumCap;

    //milestone parameters
    var etherAmount = 10;
    var tokenAmount = 1000;
    var secondEtherAmount = etherAmount + 20;
    var editedEtherAmount = etherAmount*3;
    var startTime = 1516620617;
    var duration = 3600;
    var finishTime = 0;
    var description = "test milestone";
    var result = "test result";

    it('Deploy of ICOContract.', async function() {
		icoContract = await ICOContract.new(token.address, projectWallet, sealTimestamp, minimumCap, maximumCap);
    });
 
});
