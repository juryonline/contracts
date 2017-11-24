pragma solidity ^0.4.16;



contract ERC20 {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

//Deal contract for two counterparties.
//Parties are denoted as party A and party B.
//Party A is initator, party B is acceptor.
contract InvestContract {
    //address public owner;
    address public investor;
    address public ICOContract; //not address, but reference itself

    //milestones

    struct Milestone {
        string description;
        uint etherAmount;
        uint tokenAmount;
        uint timestamp;
    }

    uint public openTime;
    uint public closeTime;
    uint public commentInterval;
    uint public verdictInterval;

    uint public partyADeposit;
    uint public partyBDeposit;

    uint public partyABalance;
    uint public partyBBalance;

    uint seedA;
    uint seedB;

    bytes32 seedHashA;
    bytes32 seedHashB;

    bool public workFinished;
    uint public commentFinished;
    uint public verdictFinished;
    address public PRNGContract;
        enum status {WillStart, // if openTime != now
                InProgress, // openTime < [InProgress]  < closeTime
                Checking,   // Testing work and allow write commnets
                            // If work is OK, next status is Closed
                Disputing, // Judges making decisions 
                Closed}   //  work is OK or judges made decisions
     
    status dealStatus;
    
    function Deal(string _title, string _description, bytes32 _partyAAddress, bytes32 _partyBAddress, address
                  _arbiterPoolAddress, uint _openTime, uint _closeTime, uint _commentInterval, uint _verdictInterval, uint
                  _partyADeposit, uint _partyBDeposit) payable {
                    description = _description;
                    title = _title;
                    partyAAddress = _partyAAddress;
                    partyBAddress = _partyBAddress;
                    arbiterPoolAddress = _arbiterPoolAddress;
                    openTime = _openTime;
                    closeTime = _closeTime;
                    commentInterval = _commentInterval;
                    verdictInterval = _verdictInterval;
                    partyADeposit = _partyADeposit;
                    partyBDeposit = _partyBDeposit;
                    workFinished = false;
                    // set status
                    if(openTime > now) { dealStatus = status(0); }
                    else { dealStatus = status(1); }
                    commentFinished = closeTime + commentInterval; 
                    owner = msg.sender;
                  }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function SetPrng(address _prng) onlyOwner {
        PRNGContract = _prng;
    }
    
    // может вызываться один раз только
    function finishWork() {
        require(workFinished == false);
        workFinished = true;
        
    }
    
    function workIsOk() {
        dealStatus = status(4); // status = closed
    }
    
    function workIsNotOK() {
        require(closeTime <= now && now <= commentFinished);
        dealStatus = status(3); // status = disput
        // выбор судей итд
    }
    
    function getRandomNumber(uint minval, uint maxval, uint _seed) constant returns(uint) {
        uint x;
        uint seed;
        PRNG prng = PRNG(PRNGContract);
        (x, seed) = prng.generate(minval, maxval, _seed);
        return x;
    }
    
    
    function getRandomNumbers(uint minval, uint maxval, uint count, uint _seed) constant returns(uint[100]) {
        PRNG prng = PRNG(PRNGContract);
        return prng.generateWithBounds(minval, maxval, count, _seed);
    }

    function setStatus(uint _status)  {
        dealStatus = status(_status);
    }
    
    modifier isDealTime() {
        require(openTime <= now && now <= closeTime);
        _;
    }
    
    modifier isCommentTime() {
        require(openTime <= commentFinished);
        _;
    }
    
    modifier isVerdictInterval() {
        require(commentFinished <= now && now <= verdictFinished);
        _;
    }

    modifier isSenderBelongToDeal() {
        require((keccak256(msg.sender) == partyAAddress) || (keccak256(msg.sender) == partyBAddress));
        _;
    }

    function getContractBalance(address erc20Aaddress) public constant returns(uint256) {
        ERC20 Jury = ERC20(erc20Aaddress);
    return Jury.balanceOf(address(this));
    }

    function getBalance(address erc20Aaddress, address partyAddress) public constant returns(uint256) {
        ERC20 Jury = ERC20(erc20Aaddress);
    return Jury.balanceOf(partyAddress);
    }

    function () payable {
            if (keccak256(msg.sender) == partyAAddress) {
                    partyABalance += msg.value;
            } else if (keccak256(msg.sender) == partyBAddress) {
                    partyBBalance += msg.value;
            } else {
                 revert();
            }
    }

    // function openDispute {} //placeholder
    // function setSeedHash {} //placeholder
    // function setSeed {} //placeholder. once both seeds are rceived select arbiters

}

