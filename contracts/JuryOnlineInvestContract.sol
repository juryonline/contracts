pragma solidity ^0.4.18;
import "./JuryOnlineICOContract.sol";
import "./Pullable.sol";


//Asynchronous send is used both for sending the Ether and tokens.
contract TokenPullable {
  using SafeMath for uint256;
  Token public token;

  mapping(address => uint256) public tokenPayments;

  function TokenPullable(address _ico) public {
      ICOContract icoContract = ICOContract(_ico);
      token = icoContract.token();
  }

  /**
  * @dev withdraw accumulated balance, called by payee.
  */
  function withdrawTokenPayment() public {
    address tokenPayee = msg.sender;
    uint256 tokenPayment = tokenPayments[tokenPayee];

    require(tokenPayment != 0);
    require(token.balanceOf(address(this)) >= tokenPayment);

    tokenPayments[tokenPayee] = 0;

    assert(token.transfer(tokenPayee, tokenPayment));
  }

  function asyncTokenSend(address _destination, uint _amount) internal {
    tokenPayments[_destination] = tokenPayments[_destination].add(_amount);
  }
}

contract InvestContract is TokenPullable, Pullable {

    address public projectWallet; // person from ico team
    address public investor; 

    uint public arbiterAcceptCount = 0;
    uint public quorum;

    ICOContract public icoContract;
    //Token public token;

    uint[] public etherPartition; //weis 
    uint[] public tokenPartition; //tokens

    //Each arbiter has parameter delay which equals time interval in seconds betwwen dispute open and when the arbiter can vote
    struct ArbiterInfo { 
        uint index;
        bool accepted;
        uint voteDelay;
    }

    mapping(address => ArbiterInfo) public arbiters; //arbiterAddress => ArbiterInfo{acceptance, voteDelay}
    address[] public arbiterList = [0x0]; //it's needed to show complete arbiter list


    //this structure can be optimized
    struct Dispute {
        uint timestamp;
        string reason;
        address[5] voters;
        mapping(address => address) votes; 
        uint votesProject;
        uint votesInvestor;
    }

    mapping(uint => Dispute) public disputes;

    uint public etherAmount; //How much Ether investor wants to invest
    uint public tokenAmount; //How many tokens investor wants to receive

    bool public disputing=false;
    uint public amountToPay; //investAmount + commissions
    
    //Modifier that restricts function caller
    modifier only(address _sender) {
        require(msg.sender == _sender);
        _;
    }

    modifier onlyArbiter() {
        require(arbiters[msg.sender].voteDelay > 0);
        _;
    }
  
    function InvestContract(address _ICOContractAddress, address _investor,  uint
                           _etherAmount, uint _tokenAmount) TokenPullable(_ICOContractAddress)
    public {
        icoContract = ICOContract(_ICOContractAddress);
        token = icoContract.token();
		etherAmount = _etherAmount;
        tokenAmount = _tokenAmount;
        projectWallet = icoContract.projectWallet();
        investor = _investor;
        amountToPay = etherAmount*101/100; //101% of the agreed amount
        quorum = 3;
        //hardcoded arbiters
        addAcceptedArbiter(0xB69945E2cB5f740bAa678b9A9c5609018314d950, 1); //Valery
        addAcceptedArbiter(0x82ba96680D2b790455A7Eee8B440F3205B1cDf1a, 1); //Valery
        addAcceptedArbiter(0x5de277bD814d95C47382CCc00718cAD3FD885c26, 1); //Valery
        addAcceptedArbiter(0x4C67EB86d70354731f11981aeE91d969e3823c39, 1); //Alex
        addAcceptedArbiter(0x2ba366D91789e54F6b5019f752E5497374bd0dE8, 1); //Alex

        arbiterAcceptCount = 5;

		uint milestoneEtherAmount; //How much Ether does investor send for a milestone
		uint milestoneTokenAmount; //How many Tokens does investor receive for a milestone

		uint milestoneEtherTarget; //How much TOTAL Ether a milestone needs
		uint milestoneTokenTarget; //How many TOTAL tokens a milestone releases

		uint totalEtherInvestment; 
		uint totalTokenInvestment;
		for(uint i=0; i<icoContract.milestonesLength(); i++) {
			(milestoneEtherTarget, milestoneTokenTarget, , , , , ) = icoContract.milestones(i);
			milestoneEtherAmount = _etherAmount * milestoneEtherTarget / icoContract.totalEther();  
			milestoneTokenAmount = _tokenAmount * milestoneTokenTarget / icoContract.totalToken();
			totalEtherInvestment += milestoneEtherAmount; //used to prevent rounding errors
			totalTokenInvestment += milestoneTokenAmount; //used to prevent rounding errors
			etherPartition.push(milestoneEtherAmount);  
			tokenPartition.push(milestoneTokenAmount);
		}
		etherPartition[0] += _etherAmount - totalEtherInvestment; //rounding error is added to the first milestone
		tokenPartition[0] += _tokenAmount - totalTokenInvestment; //rounding error is added to the first milestone
    }

    function() payable public only(investor) { 
        require(arbiterAcceptCount >= quorum);
        require(msg.value == amountToPay);
        require(getCurrentMilestone() == 0); //before first
        icoContract.investContractDeposited();
    } 

    //Adding an arbiter which has already accepted his participation in ICO.
    function addAcceptedArbiter(address _arbiter, uint _delay) internal {
        require(token.balanceOf(address(this))==0); //only callable when there are no tokens at this contract
        require(_delay > 0); //to differ from non-existent arbiters
        var index = arbiterList.push(_arbiter);
        arbiters[_arbiter] = ArbiterInfo(index, true, _delay);
    }

    function vote(address _voteAddress) public onlyArbiter {   
        require(_voteAddress == investor || _voteAddress == projectWallet);
        require(disputing);
        uint milestone = getCurrentMilestone();
        require(milestone > 0);
        require(disputes[milestone].votes[msg.sender] == 0); 
        require(now - disputes[milestone].timestamp >= arbiters[msg.sender].voteDelay); //checking if enough time has passed since dispute had been opened
        disputes[milestone].votes[msg.sender] = _voteAddress;
        disputes[milestone].voters[disputes[milestone].votesProject+disputes[milestone].votesInvestor] = msg.sender;
        if (_voteAddress == projectWallet) {
            disputes[milestone].votesProject += 1;
        } else if (_voteAddress == investor) {
            disputes[milestone].votesInvestor += 1;
        } else { 
            revert();
        }

        if (disputes[milestone].votesProject >= quorum) {
            executeVerdict(true);
        }
        if (disputes[milestone].votesInvestor >= quorum) {
            executeVerdict(false);
        }
    }

    function executeVerdict(bool _projectWon) internal {
        disputing = false;
        if (!_projectWon) {
            asyncSend(investor, balance(address(this));
            token.transfer(address(icoContract), token.balanceOf(this)); // send all tokens back
        }
        //if project won then implementation proceeds
    }

    function openDispute(string _reason) public only(investor) {
        assert(!disputing);
        var milestone = getCurrentMilestone();
        assert(milestone > 0);
        disputing = true;
        disputes[milestone].timestamp = now;
        disputes[milestone].reason = _reason;
    }

	function milestoneStarted(uint _milestone) public only(address(icoContract)) {
        require(!disputing);
		var etherToSend = etherPartition[_milestone];
		var tokensToSend = tokenPartition[_milestone];

		asyncSend(projectWallet, etherToSend); //async send
		asyncTokenSend(investor, tokensToSend);
    }

    function getCurrentMilestone() public constant returns(uint) {
        return icoContract.getCurrentMilestone();
    }

}
