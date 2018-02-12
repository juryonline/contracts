pragma solidity ^0.4.18;
import "./ERC20Token.sol";
import "./JuryOnlineInvestContract.sol";

contract ICOContract {
    
    address public projectWallet; //beneficiary wallet
    address public operator = 0x2ba366D91789e54F6b5019f752E5497374bd0dE8; //address of the ICO operator — the one who adds milestones and InvestContracts

    uint public constant waitPeriod = 7 days; //wait period after milestone finish and untile the next one can be started

    address[] public pendingInvestContracts = [0x0]; //pending InvestContracts not yet accepted by the project
    mapping(address => uint) public pendingInvestContractsIndices;

    address[] public investContracts = [0x0]; // accepted InvestContracts
    mapping(address => uint) public investContractsIndices;

    uint public minimalInvestment = 5 ether;
    
    uint public totalEther; // How much Ether is collected =sum of all milestones' etherAmount
    uint public totalToken; // how many tokens are distributed = sum of all milestones' tokenAmount

    uint public tokenLeft;
    uint public etherLeft;

    Token public token;
    
    ///ICO caps
    uint public minimumCap; // set in constructor
    uint public maximumCap;  // set in constructor

    //Structure for milestone
    struct Milestone {
        uint etherAmount; //how many Ether is needed for this milestone
        uint tokenAmount; //how many tokens releases this milestone
        uint startTime; //real time when milestone has started, set upon start
        uint finishTime; //real time when milestone has finished, set upon finish
        uint duration; //assumed duration for milestone implementation, set upon milestone creation
        string description; 
        string results;
    }

    Milestone[] public milestones;
    uint public currentMilestone;
    uint public sealTimestamp; //Until when it's possible to add new and change existing milestones

    
    modifier only(address _sender) {
        require(msg.sender == _sender);
        _;
    }

    modifier notSealed() {
        require(now <= sealTimestamp);
        _;
    }

    modifier sealed() {
        require(now > sealTimestamp);
        _;
    }

    /// @dev Create an ICOContract.
    /// @param _tokenAddress Address of project token contract
    /// @param _projectWallet Address of project developers wallet
    /// @param _sealTimestamp Until this timestamp it's possible to alter milestones
    /// @param _minimumCap Wei value of minimum cap for responsible ICO
    /// @param _maximumCap Wei value of maximum cap for responsible ICO
    function ICOContract(address _tokenAddress, address _projectWallet, uint _sealTimestamp, uint _minimumCap,
                         uint _maximumCap) public {
        token = Token(_tokenAddress);
        projectWallet = _projectWallet;
        sealTimestamp = _sealTimestamp;
        minimumCap = _minimumCap;
        maximumCap = _maximumCap;
    }

    //MILESTONES
  
    /// @dev Adds a milestone.
    /// @param _etherAmount amount of Ether needed for the added milestone
    /// @param _tokenAmount amount of tokens which will be released for added milestone
    /// @param _startTime field for start timestamp of added milestone
    /// @param _duration assumed duration of the milestone
    /// @param _description description of added milestone
    /// @param _result result description of added milestone
    function addMilestone(uint _etherAmount, uint _tokenAmount, uint _startTime, uint _duration, string _description, string _result)        
    notSealed only(operator)
    public returns(uint) {
        totalEther += _etherAmount;
        totalToken += _tokenAmount;
        uint x;
        return milestones.push(Milestone(_etherAmount, _tokenAmount, _startTime, x, _duration, _description, _result));
    }

    /// @dev Edits milestone by given id and new parameters.
    /// @param _id id of editing milestone
    /// @param _etherAmount amount of Ether needed for the milestone
    /// @param _tokenAmount amount of tokens which will be released for the milestone
    /// @param _startTime start timestamp of the milestone
    /// @param _duration assumed duration of the milestone
    /// @param _description description of the milestone
    /// @param _results result description of the milestone
    function editMilestone(uint _id, uint _etherAmount, uint _tokenAmount, uint _startTime, uint _duration, string _description, string _results) 
    notSealed only(operator)
    public {
        require(_id < milestones.length);
        totalEther = totalEther - milestones[_id].etherAmount + _etherAmount;
        totalToken = totalToken - milestones[_id].tokenAmount + _tokenAmount;
        milestones[_id].etherAmount = _etherAmount;
        milestones[_id].tokenAmount = _tokenAmount;
        milestones[_id].startTime = _startTime;
        milestones[_id].duration = _duration;
        milestones[_id].description = _description;
        milestones[_id].results = _results;
    }

    //TODO: add check if ICOContract has tokens
    ///@dev Seals milestone making them no longer changeable. Works by setting changeable timestamp to the current one, //so in future it would be no longer callable.
    function seal() only(operator) notSealed() public { 
        assert(milestones.length > 0);
        //assert(token.balanceOf(address(this)) >= totalToken;
        sealTimestamp = now;
        etherLeft = totalEther;
        tokenLeft = totalToken;
    }

    function finishMilestone(string _results) only(operator) public {
        var milestone = getCurrentMilestone();
        milestones[milestone].finishTime = now;
        milestones[milestone].results = _results;
    }

    function startNextMilestone() public only(operator) {
        uint milestone = getCurrentMilestone();
        require(milestones[currentMilestone].finishTime != 0);
        require(now > milestones[currentMilestone].finishTime + waitPeriod);
        currentMilestone +=1;
        milestones[currentMilestone].startTime = now;
        for(uint i=1; i < investContracts.length; i++) {
                InvestContract investContract =  InvestContract(investContracts[i]); 
                investContract.milestoneStarted(milestone);
        }
    }

    ///@dev Returns number of the current milestone. Starts from 1. 0 indicates that project implementation has not started yet.
    function getCurrentMilestone() public constant returns(uint) {
        /*
        for(uint i=0; i < milestones.length; i++) { 
            if (milestones[i].startTime <= now && now <= milestones[i].finishTime + waitPeriod) {
                return i+1;
            }
        }
        return 0;
       */
        return currentMilestone;
    }
   
    /// @dev Getter function for length. For testing purposes.
    function milestonesLength() public view returns(uint) {
        return milestones.length;
    }

    ///InvestContract part
    function createInvestContract(address _investor, uint _etherAmount, uint _tokenAmount) public 
        sealed only(operator)
        returns(address)
    {
        require(_etherAmount >= minimalInvestment);
        //require(milestones[0].startTime - now >= 5 days);
        //require(maximumCap >= _etherAmount + investorEther);
        //require(token.balanceOf(address(this)) >= _tokenAmount + investorTokens);
        address investContract = new InvestContract(address(this), _investor, _etherAmount, _tokenAmount);
        pendingInvestContracts.push(investContract);
        pendingInvestContractsIndices[investContract]=(pendingInvestContracts.length-1); //note that indices start from 1
        return(investContract);
    }

    /// @dev This function is called by InvestContract when it receives Ether. It shold move this InvestContract from pending to the real ones.
    function investContractDeposited() public {
        //require(maximumCap >= investEthAmount + investorEther);
        uint index = pendingInvestContractsIndices[msg.sender];
        assert(index > 0);
        uint len = pendingInvestContracts.length;
        InvestContract investContract = InvestContract(pendingInvestContracts[index]);
        pendingInvestContracts[index] = pendingInvestContracts[len-1];
        pendingInvestContracts.length = len-1;
        investContracts.push(msg.sender);
        investContractsIndices[msg.sender]=investContracts.length-1; //note that indexing starts from 1

        uint investmentToken = investContract.tokenAmount();
        uint investmentEther = investContract.etherAmount();

        etherLeft -= investmentEther;
        tokenLeft -= investmentToken;
        assert(token.transfer(msg.sender, investmentToken)); 
    }

}


