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
        assert(oldToken.allowance(msg.sender) >= _amount);
        assert(oldToken.transferFrom(address(this), msg.sender, a_mount));
        assert(newToken.transfer(msg.sender, _amount));
    }

}
