pragma solidity ^0.4.18;
import "./ERC20Token.sol";

/**
 * @title Pullable
 * @dev Base contract supporting async send for pull payments. Inherit from this
 * contract and use asyncSend instead of send. Originally taken from https://github.com/OpenZeppelin/zeppelin-solidity
 * with few changes.
 */
contract Pullable {
  using SafeMath for uint256;

  mapping(address => uint256) public etherPayments;

  /**
  * @dev withdraw accumulated balance, called by payee.
  */
  function withdrawEtherPayment() public {
    uint payment = etherPayments[msg.sender];
    require(payment != 0);
    require(address(this).balance >= payment);
    etherPayments[msg.sender] = 0;
    assert(msg.sender.send(payment));
  }

  /**
  * @dev Called by the payer to store the sent amount as credit to be pulled.
  * @param _destination The destination address of the funds.
  * @param _amount The amount to transfer.
  */
  function asyncSend(address _destination, uint256 _amount) internal {
    etherPayments[_destination] = etherPayments[_destination].add(_amount);
  }
}

//Asynchronous send is used both for sending the Ether and tokens.
contract TokenPullable {
  using SafeMath for uint256;
  Token public token;

  mapping(address => uint256) public tokenPayments;

  constructor(address _token) public {
      token = Token(_token);
  }

  /**
  * @dev withdraw accumulated balance, called by payee.
  */
  function withdrawTokenPayment() public {
    uint tokenPayment = tokenPayments[msg.sender];
    require(tokenPayment != 0);
    require(token.balanceOf(address(this)) >= tokenPayment);
    tokenPayments[msg.sender] = 0;
    assert(token.transfer(msg.sender, tokenPayment));
  }

  function asyncTokenSend(address _destination, uint _amount) internal {
    tokenPayments[_destination] = tokenPayments[_destination].add(_amount);
  }
}

