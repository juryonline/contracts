pragma solidity ^0.4.18;

//placeholder contract
contract ICOContract {
    address public projectWallet;
    address public invesotWallet;
    address public tokenAddress;

    uint public minimumSecuredInvestment; //in wei
    uint public maximumSecuredInvestment; //in wei

    address[] public investContracts;

    //addInvestContract onlyOwner
}
