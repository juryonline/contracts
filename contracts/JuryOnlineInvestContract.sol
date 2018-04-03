pragma solidity ^0.4.18;
import "./JuryOnlineICOContract.sol";
import "./Pullable.sol";

contract InvestContract is TokenPullable, Pullable {
    using SafeMath for uint;

    address public projectWallet; //beneficiary
    address public investor; 

    uint public arbiterAcceptCount;
    uint public quorum;

    ICOContract public icoContract;

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

    bool public disputing = false;
    uint public amountToPay; //investAmount + commission
    
    modifier only(address _sender) {
        require(msg.sender == _sender);
        _;
    }

    modifier onlyArbiter() {
        require(arbiters[msg.sender].voteDelay > 0);
        _;
    }

    modifier started() {
        require(getCurrentMilestone() > 0);
        _;
    }

    modifier notStarted() {
        require(getCurrentMilestone() == 0);
        _;
    }

    ///@dev Creates an InvestContract
    function InvestContract(address _ICOContractAddress, address _investor,  uint _etherAmount, uint _tokenAmount)
    TokenPullable(ICOContract(_ICOContractAddress).token()) //wierd initialization: TokenPullable needs token address and must be set before InvestContract constructor takes place 
    public {
        icoContract = ICOContract(_ICOContractAddress);
        amountToPay = _etherAmount; 
		etherAmount = _etherAmount*(100-icoContract.commission())/100; //Ether commission handling
        tokenAmount = _tokenAmount;
        projectWallet = icoContract.projectWallet();
        investor = _investor;
        quorum = 2;

        addAcceptedArbiter(0xB69945E2cB5f740bAa678b9A9c5609018314d950); //Valery
        addAcceptedArbiter(0x82ba96680D2b790455A7Eee8B440F3205B1cDf1a); //Valery
        addAcceptedArbiter(0x4C67EB86d70354731f11981aeE91d969e3823c39); //Alex

		uint milestoneEtherAmount; //How much Ether does investor send for a milestone
		uint milestoneTokenAmount; //How many Tokens does investor receive for a milestone

		uint milestoneEtherTarget; //How much TOTAL Ether a milestone needs
		uint milestoneTokenTarget; //How many TOTAL tokens a milestone releases

		uint totalEtherInvestment; 
		uint totalTokenInvestment;
		for(uint i=0; i<icoContract.milestonesLength(); i++) {
			(milestoneEtherTarget, milestoneTokenTarget, , , , , ) = icoContract.milestones(i);
			milestoneEtherAmount = etherAmount.mul(milestoneEtherTarget).div(icoContract.totalEther());  
			milestoneTokenAmount = tokenAmount.mul(milestoneTokenTarget).div(icoContract.totalToken());
			totalEtherInvestment = totalEtherInvestment.add(milestoneEtherAmount); //used to prevent rounding errors
			totalTokenInvestment = totalTokenInvestment.add(milestoneTokenAmount); //used to prevent rounding errors
			etherPartition.push(milestoneEtherAmount);  
			tokenPartition.push(milestoneTokenAmount);
		}
		etherPartition[0] += etherAmount - totalEtherInvestment; //rounding error is added to the first milestone
		tokenPartition[0] += tokenAmount - totalTokenInvestment; //rounding error is added to the first milestone
    }

    function() payable public notStarted only(investor) { 
        require(arbiterAcceptCount >= quorum);
        require(msg.value == amountToPay);
        icoContract.juryOnlineWallet().transfer(amountToPay-etherAmount);
        icoContract.investContractDeposited();
    } 

    //Adding an arbiter which has already accepted his participation in ICO.
    function addAcceptedArbiter(address _arbiter) internal notStarted {
        arbiterAcceptCount +=1;
        var index = arbiterList.push(_arbiter);
        arbiters[_arbiter] = ArbiterInfo(index, true, 1);
    }

    function addArbiter(address _arbiter, uint _delay) public notStarted only(investor) {
        require(_delay > 0);
        var index = arbiterList.push(_arbiter);
        arbiters[_arbiter] = ArbiterInfo(index, false, _delay);
    }

    function acceptArbiter() public onlyArbiter {
        require(!arbiters[msg.sender].accepted);
        arbiters[msg.sender].accepted = true;
        arbiterAcceptCount += 1;
    }

    function vote(address _voteAddress) public onlyArbiter {   
        require(disputing);
        require(_voteAddress == investor || _voteAddress == projectWallet);

        uint milestone = getCurrentMilestone();
        require(milestone > 0);
        var dispute = disputes[milestone-1];
        require(dispute.votes[msg.sender] == 0); 
        require(now - dispute.timestamp >= arbiters[msg.sender].voteDelay); //checking if enough time has passed since dispute had been opened

        dispute.votes[msg.sender] = _voteAddress; //sets the vote
        dispute.voters[dispute.votesProject+dispute.votesInvestor] = msg.sender; // this line means adding arbiter to dispute.voters
        if (_voteAddress == projectWallet) {
            dispute.votesProject += 1;
            if (dispute.votesProject >= quorum) {
                executeVerdict(true);
            }
        } else {
            dispute.votesInvestor += 1;
            if (dispute.votesInvestor >= quorum) {
                executeVerdict(false);
            }
        } 
    }

    function executeVerdict(bool _projectWon) internal {
        if (!_projectWon) {
            asyncSend(investor, this.balance);
            token.transfer(icoContract, token.balanceOf(this)); // send all tokens back
            //asyncTokenSend(token.transfer(icoContract, token.balanceOf(this))); // send all tokens back
            icoContract.deleteInvestContract();
        } else {//if project won then implementation proceeds
            disputing = false;
        }
    }

    function openDispute(string _reason) public started only(investor) {
        require(!disputing);
        uint milestone = getCurrentMilestone();
        require(milestone > 0);
        disputing = true;
        disputes[milestone-1].timestamp = now;
        disputes[milestone-1].reason = _reason;
    }

    ///@dev When new milestone is started this functions is called
	function milestoneStarted(uint _milestone) public only(icoContract) {
        require(!disputing);
		var etherToSend = etherPartition[_milestone];
		var tokensToSend = tokenPartition[_milestone];

		asyncSend(projectWallet, etherToSend); 
		asyncTokenSend(investor, tokensToSend);
    }

    function getCurrentMilestone() public view returns(uint) {
        return icoContract.currentMilestone();
    }

}
