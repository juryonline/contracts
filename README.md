# Jury.Online Contracts
This repository containts contracts for Jury.Online Responsible ICO operation.

There are two main contracts:

__ICOContract__

__InvestContract__


ICOContract is central contract for the whole ICO of the project.

A new InvestContract is created for each investor willing to contribute to the ICO of the project. It stores the
relations of investor and project.


## ICO 

To create an ICO project, the creators must provide following information:

- minimum investment amount
- minimum ICO cap 
- maximum ICO cap
- amount of tokens distibuted using Jury.Online platform

Also they must specify addresses of people involved in ICO operation:

- project wallet (the beneficiary which receives Ether)
- operator (the one who adds, starts, finishes and seals milestones)


## Milestones

Project prepares roadmap with distinct milestones. Each milestone has following information:

- formal description of results
- duration of milestone
- amount of Ether needed for implementation
- amount of tokens issued 

Before the ICO can be started project has to *seal* the __ICOContract__, so no new milestones can be added and neither existing can be changed. Seal timestamp is also needed to create an ICO project, 
it indicates when until which time the project has to finalize milestones.

## Arbiters

Each __InvestContract__ has arbiters that must be added before the __InvestContract__ is added to the __ICOContract__.

Arbiters are added to the __InvestContract__ by __investor__. 

Arbiters are responsible for deciding funds and token transfer in case of dispute. 

So in case arbiters has disappeared funds and tokens are stuck in the smart contract, which is quite an unwanted
outcome. Such potential outcome is bypassed using additional parameter for each arbiter — *delay*.

*Delay* is time interval between dispute start and the moment when arbiter may provide his decision. Using this
method allows to add 'reserve' arbiters, which provide their decision in case the 'main' arbiters hadn't provide theirs
in time. 

Investor adds arbiter with specified delay times, so he can arrange who of them is going to be 'main' arbiter and who is 'reserve' one.

Still it's not enought, as 'reserve' arbiters can lose their account keys, be unavailable or dissapear without a trace
by any other reason. Therefore both project and investor are added as arbiters with significant delay times. 

* Investor - 4 weeks
* Project - 6 weeks


## Disputes

At any moment after the first milestone has started investor can open a dispute (it requires a reason to be opened).

After a dispute is opened 

For a dispute to be resolved, either investor or project must receive a specified amount of votes — *quorum* (to be
precise, it's not the right term, as quorum is a minimum number of members needed to conduct an action). 

When there is at least one not resolved dispute new milestone cannot be started.


# Operation

1. Project creates roadmap with milestones.
2. Project specifies target ICO result.

Whent a milestone is started Ether and tokens for this milestone are sent to project and investor.

Each milestone is finished manually by the project. Project has to specify results, links to it are stored in blockchain.


# Jury.Online ICO
Contracts for Jury.Online ICO are a bit different from the general ones used for other projects at the platform. They are prepended with "JuryOnline".

In fact the differences are:
1. No need to handle JOT commission for our own ICO.
2. Arbiters are fixed for all InvestContracts.

# Jury.Online Token

Jury.Online Token contract address: 

[0xdb455c71c1bc2de4e80ca451184041ef32054001](https://etherscan.io/token/0xdb455c71c1bc2de4e80ca451184041ef32054001)


For responsible ICO we issued another token which later (after the original one becomes transferrable by the end of ICO)
can be exchanged for the original in 1:1 rate.

Jury.Online Token for Responsible ICO (JOTR) contract address: 

[0x9070e2fDb61887c234D841c95D1709288EBbB9a0](https://etherscan.io/token/0x9070e2fDb61887c234D841c95D1709288EBbB9a0)

# License 

This repository is using GNU General Public License Version 3.
