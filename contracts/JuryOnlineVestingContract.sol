pragma solidity ^0.4.18;
import "./ERC20Token.sol";


//This contract is used to distributed tokens reserved for Jury.Online team the terms of distirbution are following:
//after the end of ICO tokens are frozen for 6 months and afterwards each months 10% of tokens is unfrozen

contract Vesting {

    //Alexander Shevtsov (founder)  0x4C67EB86d70354731f11981aeE91d969e3823c39
    //Anastasia Bormotova (PR)      0x450Eb50Cc83B155cdeA8b6d47Be77970Cf524368
    //Artemiy Pirozhkov (COO)       0x9CFf3408a1eB46FE1F9de91f932FDCfEC34A568f
    //Konstantin Kudryavtsev (CTO)  0xA14d9fa5B1b46206026eA51A98CeEd182A91a190
    //Marina Kobyakova (BD)         0x0465f2fA674bF20Fe9484dB70D8570617495b352
    //Nikita Alekseev (Design)      0x07F8a6Fb0Ad63abBe21e8ef33523D8368618cd10
    //Nikolay Prudnikov (Marketing) 0xF29fE8e258b084d40D9cF1dCF02E5CB29837b6D5
    //Valeriy Strechen (Marketing)  0x64B557EaED227B841DcEd9f70918cd8f5ca2Bdab

    uint public startTime;
    uint public constant intervals;
    uint public currentStage;
    address[10] public team;
    Token public token;

    function Vesting(address[10] _team, address _token) {
        token = Token(_token);
        startTime = now;
        for(uint i=0; i<team.length; i++) {
            //team[i]=
        }
    }

    function makePayout() {
        for(uint i=1; i<team.legngth; i++) {
            token.transfer(team[i], balance);



        }

        currentStage+=1;
    }



}
