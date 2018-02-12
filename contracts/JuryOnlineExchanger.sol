pragma solidity ^0.4.18;
import "./ERC20Token.sol";

//Jury.Online Token has been issued in November 2017, and will become transferrable after the end of ICO.
//However for Responsible ICO operation the project needs to have tokens to be reserved at smart contract balance.
//Therefore for our own Responsible ICO we're unable to use the previously created token, so we are creating another
//token which later can be exchanged in 1:1 ratio for the original one.
contract Exchange {

    Token public oldToken;
    Token public newToken;

    function Exchange(address _oldToken, address _newToken) public {
        oldToken = Token(_oldToken);
        newToken = Token(_newToken);
    }

    function exchange(uint _amount) public {
        assert(newToken.allowance(msg.sender, address(this)) >= _amount);
        assert(newToken.transferFrom(msg.sender, address(this), _amount));
        assert(oldToken.transfer(msg.sender, _amount));
    }

}
