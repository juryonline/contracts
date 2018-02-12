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

  mapping(address => uint256) public payments;

  /**
  * @dev withdraw accumulated balance, called by payee.
  */
  function withdrawPayment() public {
    address payee = msg.sender;
    uint256 payment = payments[payee];

    require(payment != 0);
    require(this.balance >= payment);

    payments[payee] = 0;

    assert(payee.send(payment));
  }

  /**
  * @dev Called by the payer to store the sent amount as credit to be pulled.
  * @param _destination The destination address of the funds.
  * @param _amount The amount to transfer.
  */
  function asyncSend(address _destination, uint256 _amount) internal {
    payments[_destination] = payments[_destination].add(_amount);
  }
}
