pragma solidity ^0.4.18;
import "./ICOContract.sol";
import "./Pullable.sol";

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
        quorum = 3;
        //addReserveArbiter(juryOnlineArbiter) //to prevent freeze of money
        //addReserveArbiter(juryOnlineArbiter) //to prevent freeze of money
        arbiterAcceptCount = 3;

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
        //require(msg.value == needPay);
        //require(getCurrentMilestone() == 0); //before first
        icoContract.investContractDeposited();
    } 

    function addArbiter(address _arbiter, uint _delay) public {
        //only(investor)
        require(token.balanceOf(address(this))==0); //only callable when there are no tokens at this contract
        require(_delay > 0); //to differ from non-existent arbiters
        var index = arbiterList.push(_arbiter);
        arbiters[_arbiter] = ArbiterInfo(index, false, _delay);
    }

    function addReserveArbiter(address _arbiter, uint _delay) internal {
        require(_delay > 0); //to differ from non-existent arbiters
        var index = arbiterList.push(_arbiter);
        arbiters[_arbiter] = ArbiterInfo(index, true, _delay);
    }

    function arbiterAccept() public onlyArbiter {
        require(!arbiters[msg.sender].accepted);
        arbiters[msg.sender].accepted = true;
        arbiterAcceptCount += 1;
    }

    function vote(address _voteAddress) public onlyArbiter 
    {   
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
            //executeVerdict(milestone);
            executeVerdict(true);
        }
        if (disputes[milestone].votesInvestor >= quorum) {
            executeVerdict(false);
            //executeVerdict(milestone);
        }
    }

    function executeVerdict(bool _projectWon) internal {
        //uint milestone = getCurrentMilestone();
        disputing = false;
        if (_projectWon) {
            //token.transfer(0x0, token.balanceOf(address(this)));
        } else  {
		//asyncTokenSend(investor, tokensToSend);
		//asyncSend(projectWallet, etherToSend);
            //token.transfer(address(icoContract), token.balanceOf(this)); // send all tokens back
        }
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

		//async send
		asyncSend(projectWallet, etherToSend);
		asyncTokenSend(investor, tokensToSend);

    }

    function getCurrentMilestone() public constant returns(uint) {
        return icoContract.getCurrentMilestone();
    }

}
