pragma solidity ^0.4.18;
import "./ERC20Token.sol";
import "./JuryOnlineInvestContract.sol";

contract ICOContract {
    using SafeMath for uint;
    
    address public projectWallet; //beneficiary wallet
    address public operator; //address of the ICO operator — the one who adds milestones and InvestContracts

    address public juryOnlineWallet = 0x3e134C5dAf56e0e28bd04beD46969Bd516932f02; //address that receives commission
    uint public commission = 1; //in percents

    //uint constant waitPeriod = 7 days; //wait period after milestone finish and until the next one can be started

    mapping(address => bool) public pendingInvestContracts; //pending = not yet paid

    address[] public investContracts = [0x0]; // accepted InvestContracts
    mapping(address => uint) public investContractsIndices;

    uint public totalEther; // How much Ether is collected = sum of all milestones' etherAmount
    uint public totalToken; // how many tokens are distributed = sum of all milestones' tokenAmount

    uint public tokenLeft;
    uint public etherLeft;

    Token public token;
    
    ///ICO caps
    uint public minimumCap; // set in constructor
    uint public maximumCap;  // set in constructor

    uint public minimalInvestment;
    
    //Structure for milestone
    struct Milestone {
        uint etherAmount; //how many Ether is needed for this milestone
        uint tokenAmount; //how many tokens releases this milestone
        uint startTime; //real time when milestone has started, set upon start
        uint finishTime; //real time when milestone has finished, set upon finish
        uint duration; //assumed duration for milestone implementation, set upon milestone creation
        string description; 
        string result;
    }

    Milestone[] public milestones;
    uint public currentMilestone; //0 indicates that no milestone has started, so the real ones start from 1
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

    modifier started() {
        require(currentMilestone > 0);
        _;
    }

    modifier notStarted() {
        require(currentMilestone == 0);
        _;
    }

    /// @dev Create an ICOContract.
    /// @param _tokenAddress Address of project token contract
    /// @param _projectWallet Address of project developers wallet
    /// @param _sealTimestamp Until this timestamp it's possible to alter milestones
    /// @param _minimumCap Wei value of minimum cap for responsible ICO
    /// @param _maximumCap Wei value of maximum cap for responsible ICO
    /// @param _operator ICO operator, the person who adds, starts, and finishes milestones; creates InvestContracts 
    function ICOContract(address _tokenAddress, address _projectWallet, uint _sealTimestamp, uint _minimumCap,
                         uint _maximumCap, uint _minimalInvestment, address _operator) public {
        operator = _operator;
        token = Token(_tokenAddress);
        projectWallet = _projectWallet;
        sealTimestamp = _sealTimestamp;
        minimumCap = _minimumCap;
        maximumCap = _maximumCap;
        minimalInvestment = _minimalInvestment;
    }
  
    /// @dev Adds a milestone.
    /// @param _etherAmount amount of Ether needed for the added milestone
    /// @param _tokenAmount amount of tokens which will be released for added milestone
    /// @param _startTime field for start timestamp of added milestone
    /// @param _duration assumed duration of the milestone
    /// @param _description description of added milestone
    function addMilestone(uint _etherAmount, uint _tokenAmount, uint _startTime, uint _duration, string _description) public notSealed only(operator) returns(uint) {
        totalEther = totalEther.add(_etherAmount);
        totalToken = totalToken.add(_tokenAmount);
        return milestones.push(Milestone(_etherAmount, _tokenAmount, _startTime, 0, _duration, _description, ""));
    }

    /// @dev Edits milestone by given id and new parameters.
    /// @param _id id of editing milestone
    /// @param _etherAmount amount of Ether needed for the milestone
    /// @param _tokenAmount amount of tokens which will be released for the milestone
    /// @param _startTime start timestamp of the milestone
    /// @param _duration assumed duration of the milestone
    /// @param _description description of the milestone
    function editMilestone(uint _id, uint _etherAmount, uint _tokenAmount, uint _startTime, uint _duration, string _description) public notSealed only(operator) {
        assert(_id < milestones.length);
        totalEther = (totalEther - milestones[_id].etherAmount).add(_etherAmount); //previous addition 
        totalToken = (totalToken - milestones[_id].tokenAmount).add(_tokenAmount);
        milestones[_id].etherAmount = _etherAmount;
        milestones[_id].tokenAmount = _tokenAmount;
        milestones[_id].startTime = _startTime;
        milestones[_id].duration = _duration;
        milestones[_id].description = _description;
    }

    //TODO: add check if ICOContract has tokens
    ///@dev Seals milestone making them no longer changeable. Works by setting changeable timestamp to the current one, //so in future it would be no longer callable.
    function seal() public notSealed only(operator) { 
        require(milestones.length > 1); //Has to have at least 2 milestones
        //require(token.balanceOf(this) >= totalToken;
        sealTimestamp = now;
        etherLeft = totalEther;
        tokenLeft = totalToken;
    }

    ///in fact modifier started is useless, as it will throw if currentMilestone <1, however it remains here for readability
    ///@dev Finishes milestone
    ///@param _result milestone result
    function finishMilestone(string _result) public started only(operator) {
        require(milestones[currentMilestone-1].finishTime == 0); //can be called only once
        milestones[currentMilestone-1].finishTime = now;
        milestones[currentMilestone-1].result = _result;
    }

    ///@dev Starts next milestone
    function startNextMilestone() public sealed only(operator) {
        require(currentMilestone != milestones.length); //checking if final milestone. There should be more than 1 milestone in the project
        if (currentMilestone != 0) {
            require(milestones[currentMilestone-1].finishTime != 0);//previous milestone has to be finished
        }
        milestones[currentMilestone].startTime = now; //setting the of the next milestone
        for(uint i=1; i < investContracts.length; i++) {
                InvestContract investContract =  InvestContract(investContracts[i]); 
                investContract.milestoneStarted(currentMilestone);
        }
        currentMilestone +=1;
    }

    //InvestContract part
    /// @dev Adds InvestContract at given addres to the pending (waiting for payment) InvestContracts
    /// @param _investContractAddress address of InvestContract
    function addInvestContract(address _investContractAddress) public sealed notStarted only(operator) {
        InvestContract investContract = InvestContract(_investContractAddress);
        require(investContract.icoContract() == this);
        require(investContract.etherAmount() >= minimalInvestment);
        //require(milestones[0].startTime - now >= 5 days);
        //require(maximumCap >= _etherAmount + investorEther);
        //require(token.balanceOf(this) >= _tokenAmount + investorTokens);
        pendingInvestContracts[_investContractAddress] = true; 
    }

    /// @dev This function is called by InvestContract when it receives Ether. It moves this InvestContract from pending to the real ones.
    function investContractDeposited() public notStarted {
        require(pendingInvestContracts[msg.sender]);
        delete pendingInvestContracts[msg.sender];
        investContracts.push(msg.sender);
        investContractsIndices[msg.sender]=investContracts.length-1;

        InvestContract investContract = InvestContract(msg.sender);
        uint investmentToken = investContract.tokenAmount();
        uint investmentEther = investContract.etherAmount();

        etherLeft = etherLeft.sub(investmentEther);
        tokenLeft = tokenLeft.sub(investmentToken);
        assert(token.transfer(msg.sender, investmentToken)); 
    }

    /// @dev If investor has won the dispute, then InvestContract is deleted by calling this function
    function deleteInvestContract() public started {
        uint index = investContractsIndices[msg.sender];
        require(index > 0);
        uint len = investContracts.length;
        investContracts[index] = investContracts[len-1];
        investContracts.length = len-1;
        delete investContractsIndices[msg.sender];
    }

    /// @dev Sends all unused tokens to projectWallet
    function returnTokens() public only(operator) {
        uint balance = token.balanceOf(this);
        token.transfer(projectWallet, balance);
    }

    ///@dev Returns number of the current milestone. Starts from 1. 0 indicates that project implementation has not started yet.
    function getCurrentMilestone() public view returns(uint) {
        return currentMilestone;
    }
   
    /// @dev Getter function for length. For testing purposes.
    function milestonesLength() public view returns(uint) {
        return milestones.length;
    }

}
